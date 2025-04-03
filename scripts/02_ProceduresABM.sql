/*
Aurora SA
Script de creacion de procedures ABM (Alta - Baja - Modificacion)
GRodriguezAR
*/

------------------------------- FUNCIONES DE UTILIDAD -------------------------------------------
-- Validar el formato del CUIL (XX-XXXXXXXX-X) incluyendo dígito verificador
CREATE FUNCTION Utilidades.ValidarCuil(@cuil VARCHAR(25))
RETURNS TABLE
AS
RETURN (
    SELECT 
        CASE 
            WHEN @cuil IS NULL THEN 0
            WHEN LEN(cuil) <> 11 THEN 0
            ELSE 
                CASE 
                    WHEN (11 - (
                        CAST(SUBSTRING(cuil, 1, 1) AS INT)*5 +
                        CAST(SUBSTRING(cuil, 2, 1) AS INT)*4 +
                        CAST(SUBSTRING(cuil, 3, 1) AS INT)*3 +
                        CAST(SUBSTRING(cuil, 4, 1) AS INT)*2 +
                        CAST(SUBSTRING(cuil, 5, 1) AS INT)*7 +
                        CAST(SUBSTRING(cuil, 6, 1) AS INT)*6 +
                        CAST(SUBSTRING(cuil, 7, 1) AS INT)*5 +
                        CAST(SUBSTRING(cuil, 8, 1) AS INT)*4 +
                        CAST(SUBSTRING(cuil, 9, 1) AS INT)*3 +
                        CAST(SUBSTRING(cuil, 10, 1) AS INT)*2
                    ) % 11) = 10
                    THEN CASE WHEN CAST(RIGHT(cuil, 1) AS INT) = 9 THEN 1 ELSE 0 END
                    ELSE CASE 
                            WHEN CAST(RIGHT(cuil, 1) AS INT) = 
                                (11 - (
                                    CAST(SUBSTRING(cuil, 1, 1) AS INT)*5 +
                                    CAST(SUBSTRING(cuil, 2, 1) AS INT)*4 +
                                    CAST(SUBSTRING(cuil, 3, 1) AS INT)*3 +
                                    CAST(SUBSTRING(cuil, 4, 1) AS INT)*2 +
                                    CAST(SUBSTRING(cuil, 5, 1) AS INT)*7 +
                                    CAST(SUBSTRING(cuil, 6, 1) AS INT)*6 +
                                    CAST(SUBSTRING(cuil, 7, 1) AS INT)*5 +
                                    CAST(SUBSTRING(cuil, 8, 1) AS INT)*4 +
                                    CAST(SUBSTRING(cuil, 9, 1) AS INT)*3 +
                                    CAST(SUBSTRING(cuil, 10, 1) AS INT)*2
                                ))
                            THEN 1 
                            ELSE 0 
                         END
                    END
        END AS Valido
    FROM (SELECT REPLACE(REPLACE(@cuil, '-', ''), ' ', '') AS cuil) AS t
);
GO

----------------------------------------------------------------------------------------------
-- ABM Empresa.Sucursal
CREATE PROCEDURE Empresa.InsertarSucursal_sp
	@codigoSucursal	 VARCHAR(25),
    @direccion       NVARCHAR(100),
    @ciudad          VARCHAR(50),
    @telefono        VARCHAR(25),
    @horario         VARCHAR(55)	
AS
BEGIN
    SET NOCOUNT ON;

    IF @codigoSucursal NOT LIKE '[A-Z][A-Z][0-9]'
	BEGIN
		RAISERROR('El formato de código de sucursal es inválido.', 16, 1);
		RETURN;
	END;

	IF EXISTS (SELECT 1 FROM Empresa.Sucursal WHERE codigoSucursal = @codigoSucursal)
	BEGIN
		RAISERROR('Ya existe una sucursal con ese código.', 16, 1);
		RETURN;
	END;

    IF @telefono NOT LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]'
	BEGIN
		RAISERROR('El formato de teléfono es inválido.', 16, 1);
		RETURN;
	END;

	IF LEN(LTRIM(RTRIM(@direccion))) = 0
    BEGIN
         RAISERROR('La direccion no puede estar vacía.', 16, 1);
         RETURN;
    END

	IF LEN(LTRIM(RTRIM(@ciudad))) = 0
    BEGIN
         RAISERROR('La ciudad no puede estar vacía.', 16, 1);
         RETURN;
    END
   
   	IF LEN(LTRIM(RTRIM(@horario))) = 0
    BEGIN
         RAISERROR('EL horario no puede estar vacío.', 16, 1);
         RETURN;
    END

	INSERT INTO Empresa.Sucursal (
        codigoSucursal,
		direccion,
        ciudad,
        telefono,
		horario
	)
    VALUES (
		@codigoSucursal,
        @direccion,
        @ciudad,
        @telefono,
		@horario
    );
END;
GO

----------------------------------------------------------------------------------------------
CREATE PROCEDURE Empresa.ActualizarSucursal_sp
    @codigoSucursal  VARCHAR(25),
    @direccion       NVARCHAR(100) = NULL,
    @ciudad          VARCHAR(50) = NULL,
    @telefono        VARCHAR(25) = NULL,
    @horario         VARCHAR(55) = NULL,
	@nuevoCodigo	 VARCHAR(25) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @direccion IS NULL AND @ciudad IS NULL AND @telefono IS NULL AND @horario IS NULL AND @nuevoCodigo IS NULL
    BEGIN
        RAISERROR('Debe indicar al menos un cambio.', 16, 1);
		RETURN;
    END

    IF @codigoSucursal NOT LIKE '[A-Z][A-Z][0-9]'
	BEGIN
		RAISERROR('El formato de código de sucursal es inválido.', 16, 1);
		RETURN;
	END;

	-- Verificacion sucursal existente
    IF NOT EXISTS (SELECT 1 FROM Empresa.Sucursal WHERE codigoSucursal = @codigoSucursal AND activo = 1)
    BEGIN    
		RAISERROR('No existe la sucursal indicada o no se encuentra activa.', 16, 1);
		RETURN;
	END

    IF @telefono NOT LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]'
	BEGIN
		RAISERROR('El formato de teléfono es inválido.', 16, 1);
		RETURN;
	END

	IF LEN(LTRIM(RTRIM(@direccion))) = 0
    BEGIN
         RAISERROR('La direccion no puede estar vacía.', 16, 1);
         RETURN;
    END

	IF LEN(LTRIM(RTRIM(@ciudad))) = 0
    BEGIN
         RAISERROR('La ciudad no puede estar vacía.', 16, 1);
         RETURN;
    END
   
   	IF LEN(LTRIM(RTRIM(@horario))) = 0
    BEGIN
         RAISERROR('El horario no puede estar vacío.', 16, 1);
         RETURN;
    END

    IF @nuevoCodigo IS NOT NULL AND @nuevoCodigo <> @codigoSucursal
    BEGIN
        IF @nuevoCodigo NOT LIKE '[A-Z][A-Z][0-9]'
        BEGIN
             RAISERROR('El formato del nuevo código de sucursal es inválido.', 16, 1);
             RETURN;
        END;
        
        IF EXISTS (SELECT 1 FROM Empresa.Sucursal WHERE codigoSucursal = @nuevoCodigo)
        BEGIN
             RAISERROR('El nuevo código de sucursal ya está en uso.', 16, 1);
             RETURN;
        END;
    END

    UPDATE Empresa.Sucursal
	SET direccion		= ISNULL(@direccion, direccion),
		ciudad			= ISNULL(@ciudad, ciudad),
		telefono		= ISNULL(@telefono, telefono),
		horario			= ISNULL(@horario, horario),
		codigoSucursal	= ISNULL(@nuevoCodigo, codigoSucursal)
	WHERE codigoSucursal = @codigoSucursal;
	
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Empresa.EliminarSucursal_sp
    @codigoSucursal VARCHAR(25)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Empresa.Sucursal WHERE codigoSucursal = @codigoSucursal AND activo = 1)
	BEGIN
        RAISERROR('No existe la sucursal indicada o no se encuentra activa.', 16, 1);
		RETURN;
	END

    -- Borrado lógico
    UPDATE Empresa.Sucursal
    SET activo = 0
    WHERE codigoSucursal = @codigoSucursal;
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Empresa.ReactivarSucursal_sp
    @codigoSucursal VARCHAR(25)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Empresa.Sucursal WHERE codigoSucursal = @codigoSucursal AND activo = 0)
	BEGIN
        RAISERROR('No existe la sucursal indicada o ya se encuentra activa.', 16, 1);
		RETURN;
	END

    -- Borrado lógico
    UPDATE Empresa.Sucursal
    SET activo = 1
    WHERE codigoSucursal = @codigoSucursal;
END;
GO

----------------------------------------------------------------------------------------------
-- ABM Empresa.Cargo
CREATE PROCEDURE Empresa.InsertarCargo_sp
	@nombre      VARCHAR(20),
    @descripcion NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM Empresa.Cargo WHERE nombre = @nombre)
	BEGIN
        RAISERROR('El cargo ya existe.', 16, 1);
		RETURN;
	END

	IF LEN(LTRIM(RTRIM(@nombre))) = 0
    BEGIN
         RAISERROR('El nombre del cargo no puede estar vacío.', 16, 1);
         RETURN;
    END
	
	IF LEN(LTRIM(RTRIM(@descripcion))) = 0
    BEGIN
         RAISERROR('La descripción del cargo no puede estar vacía.', 16, 1);
         RETURN;
    END

	INSERT INTO Empresa.Cargo (
        nombre,
		descripcion
	)
    VALUES (
		@nombre,
		@descripcion
	);
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Empresa.ActualizarCargo_sp
	@nombre      VARCHAR(20),
    @descripcion NVARCHAR(100) = NULL,
	@nuevoNombre VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @descripcion IS NULL AND @nuevoNombre IS NULL
    BEGIN
        RAISERROR('Debe indicar al menos un cambio.', 16, 1);
		RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Empresa.Cargo WHERE nombre = @nombre AND activo = 1)
	BEGIN
        RAISERROR('El cargo no existe o no se encuentra activo.', 16, 1);
		RETURN;
	END

    IF LEN(LTRIM(RTRIM(@descripcion))) = 0
    BEGIN
         RAISERROR('La descripción del cargo no puede estar vacía.', 16, 1);
         RETURN;
    END

	IF @nuevoNombre IS NOT NULL AND @nuevoNombre <> @nombre 
	BEGIN
		IF LEN(LTRIM(RTRIM(@nombre))) = 0
        BEGIN
            RAISERROR('El nuevo nombre del cargo no puede estar vacío.', 16, 1);
            RETURN;
        END

		IF EXISTS (SELECT 1 FROM Empresa.Cargo WHERE nombre = @nuevoNombre)
		BEGIN
			RAISERROR('El nuevo nombre del cargo ya está en uso.', 16, 1);
			RETURN;
		END
	END

    UPDATE Empresa.Cargo
    SET descripcion = ISNULL(@descripcion, descripcion),
		nombre      = ISNULL(@nuevoNombre,nombre)
    WHERE nombre = @nombre;
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Empresa.EliminarCargo_sp
	@nombre VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Empresa.Cargo WHERE nombre = @nombre AND activo = 1)
	BEGIN
        RAISERROR('El cargo no existe o no se encuentra activo.', 16, 1);
		RETURN;
	END

    UPDATE Empresa.Cargo
    SET activo = 0
    WHERE nombre = @nombre;
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Empresa.ReactivarCargo_sp
	@nombre VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Empresa.Cargo WHERE nombre = @nombre AND activo = 0)
	BEGIN
        RAISERROR('El cargo no existe o no ya se encuentra activo.', 16, 1);
		RETURN;
	END

    UPDATE Empresa.Cargo
    SET activo = 1
    WHERE nombre = @nombre;
END;
GO

----------------------------------------------------------------------------------------------
-- ABM Empresa.Turno
CREATE PROCEDURE Empresa.InsertarTurno_sp
	@acronimo    VARCHAR(25),
    @descripcion VARCHAR(25)
AS
BEGIN
    SET NOCOUNT ON;

    IF @acronimo NOT LIKE '[A-Z][A-Z]'
	BEGIN
        RAISERROR('El formato de turno es inválido.', 16, 1);
		RETURN;
	END

    IF EXISTS (SELECT 1 FROM Empresa.Turno WHERE acronimo = @acronimo)
	BEGIN
        RAISERROR('El turno ya existe.', 16, 1);
		RETURN;
	END

    IF LEN(LTRIM(RTRIM(@descripcion))) = 0
    BEGIN
         RAISERROR('La descripción del turno no puede estar vacía.', 16, 1);
         RETURN;
    END

	INSERT INTO Empresa.Turno (
        acronimo,
		descripcion
	)
    VALUES (
		@acronimo,
		@descripcion
	);
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Empresa.ActualizarTurno_sp
	@acronimo       VARCHAR(25),
    @descripcion    NVARCHAR(25) = NULL,
	@nuevoAcronimo  VARCHAR(25) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @descripcion IS NULL AND @nuevoAcronimo IS NULL
    BEGIN
        RAISERROR('Debe indicar al menos un cambio.', 16, 1);
		RETURN;
    END

    IF @acronimo NOT LIKE '[A-Z][A-Z]'
	BEGIN
        RAISERROR('El formato de turno es inválido.', 16, 1);
		RETURN;
	END

    IF NOT EXISTS (SELECT 1 FROM Empresa.Turno WHERE acronimo = @acronimo AND activo = 1)
	BEGIN
        RAISERROR('El turno no existe o no se encuentra activo.', 16, 1);
		RETURN;
	END

	IF LEN(LTRIM(RTRIM(@descripcion))) = 0
    BEGIN
         RAISERROR('La nueva descripción del turno no puede estar vacía.', 16, 1);
         RETURN;
    END

	IF @nuevoAcronimo IS NOT NULL AND @nuevoAcronimo <> @acronimo 
	BEGIN
	    IF @nuevoAcronimo NOT LIKE '[A-Z][A-Z]'
	    BEGIN
            RAISERROR('El formato del nuevo acrónimo es inválido.', 16, 1);
		    RETURN;
	    END

		IF EXISTS (SELECT 1 FROM Empresa.Turno WHERE acronimo = @nuevoAcronimo)
		BEGIN
			RAISERROR('El nuevo acronimo de turno ya está en uso.', 16, 1);
			RETURN;
		END
	END

    UPDATE Empresa.Turno
    SET descripcion = ISNULL(@descripcion, descripcion),
		acronimo    = ISNULL(@nuevoAcronimo, acronimo)
    WHERE acronimo = @acronimo;
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Empresa.EliminarTurno_sp
	@acronimo VARCHAR(25) 
AS
BEGIN
    SET NOCOUNT ON;

    IF @acronimo NOT LIKE '[A-Z][A-Z]'
	BEGIN
        RAISERROR('El formato de turno es inválido.', 16, 1);
		RETURN;
	END

    IF NOT EXISTS (SELECT 1 FROM Empresa.Turno WHERE acronimo = @acronimo AND activo = 1)
	BEGIN
        RAISERROR('El turno no existe o no se encuentra activo.', 16, 1);
		RETURN;
	END

    UPDATE Empresa.Turno
    SET activo = 0
    WHERE acronimo = @acronimo;
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Empresa.ReactivarTurno_sp
	@acronimo VARCHAR(25) 
AS
BEGIN
    SET NOCOUNT ON;

    IF @acronimo NOT LIKE '[A-Z][A-Z]'
	BEGIN
        RAISERROR('El formato de turno es inválido.', 16, 1);
		RETURN;
	END

    IF NOT EXISTS (SELECT 1 FROM Empresa.Turno WHERE acronimo = @acronimo AND activo = 0)
	BEGIN
        RAISERROR('El turno no existe o ya se encuentra activo.', 16, 1);
		RETURN;
	END

    UPDATE Empresa.Turno
    SET activo = 1
    WHERE acronimo = @acronimo;
END;
GO

----------------------------------------------------------------------------------------------
-- ABM Empresa.Empleado
CREATE PROCEDURE Empresa.InsertarEmpleado_sp
    @legajo         INT,
    @nombre			VARCHAR(30),
    @apellido		VARCHAR(30),
    @genero			VARCHAR(25),
    @cuil			VARCHAR(25),
    @telefono		VARCHAR(25),
    @domicilio		NVARCHAR(100),
    @fechaAlta		DATE = NULL,
    @mailPersonal	VARCHAR(55),
    @mailEmpresa	VARCHAR(55),
    @cargo          VARCHAR(20),
    @sucursal       VARCHAR(25),
    @turno          VARCHAR(25)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @idCargo    INT,
            @idSucursal INT,
            @idTurno    INT

    IF @legajo <= 0
    BEGIN
		RAISERROR('El formato de legajo es inválido.',16,1)
		RETURN;
	END

    IF EXISTS (SELECT 1 FROM Empresa.Empleado WHERE legajo = @legajo)
    BEGIN
		RAISERROR('El legajo ya está registrado.', 16, 1);
        RETURN;
	END

	-- Verificacion formato de cuil
	IF Utilidades.ValidarCuil(@cuil) = 0
	BEGIN
		RAISERROR('El formato de cuil es inválido.',16,1)
		RETURN;
	END
	
	IF EXISTS (SELECT 1 FROM Empresa.Empleado WHERE cuilHASH = HASHBYTES('SHA2_512', @cuil))
    BEGIN
		RAISERROR('El empleado ya existe.', 16, 1);
        RETURN;
	END

    IF LEN(LTRIM(RTRIM(@nombre))) = 0
    BEGIN
         RAISERROR('El nombre del empleado no puede estar vacío.', 16, 1);
         RETURN;
    END

    IF LEN(LTRIM(RTRIM(@apellido))) = 0
    BEGIN
         RAISERROR('El apellido del empleado no puede estar vacío.', 16, 1);
         RETURN;
    END

	IF UPPER(@genero) NOT IN ('M', 'F')
	BEGIN
		RAISERROR('El formato del género es inválido.',16,1)
		RETURN;
	END
	
	IF @telefono NOT LIKE '11[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
	BEGIN
		RAISERROR('El formato de teléfono es inválido.', 16, 1);
		RETURN;
	END

    IF LEN(LTRIM(RTRIM(@domicilio))) = 0
    BEGIN
         RAISERROR('El domicilio del empleado no puede estar vacío.', 16, 1);
         RETURN;
    END

	-- Verificacion formato de mail
	IF @mailPersonal NOT LIKE '_%@_%._%' 
	BEGIN
		RAISERROR('El formato de mail personal es inválido.', 16, 1);
		RETURN;
	END

	IF LOWER(@mailEmpresa) NOT LIKE '_%@aurorasa.com.ar' 
	BEGIN
		RAISERROR('El formato de mail de la empresa es inválido.', 16, 1);
		RETURN;
	END

    SET @idCargo = (SELECT idCargo FROM Empresa.Cargo WHERE nombre = @cargo AND activo = 1)
    IF @idCargo IS NULL
    BEGIN
	    RAISERROR('El cargo no existe o no está activo.', 16, 1);
        RETURN;
    END

    IF @sucursal NOT LIKE '[A-Z][A-Z][0-9]'
    BEGIN
        RAISERROR('El formato de sucursal es inválido', 16, 1);
        RETURN;
    END

    SET @idSucursal = (SELECT idSucursal FROM Empresa.Sucursal WHERE codigoSucursal = @sucursal AND activo = 1)
    IF @idSucursal IS NULL
    BEGIN
	    RAISERROR('La sucursal no existe o no está activa.', 16, 1);
        RETURN;
    END

    IF @turno NOT LIKE '[A-Z][A-Z]'
    BEGIN
        RAISERROR('El formato de turno es inválido', 16, 1);
        RETURN;
    END

    SET @idTurno = (SELECT idTurno FROM Empresa.Turno WHERE acronimo = @turno AND activo = 1)
    IF @idCargo IS NULL
    BEGIN
	    RAISERROR('El turno no existe o no está activo.', 16, 1);
        RETURN;
    END

    INSERT INTO Empresa.Empleado (
        legajo,
		nombre,
        apellido,
		genero,
        cuil,
        cuilHASH,
        telefono, 
        domicilio,
		fechaAlta,
		mailPersonal,
		mailEmpresa,
        idCargo,
        idSucursal,
        idTurno
    )
	VALUES (
        @legajo,
		@nombre,	
		@apellido,
		UPPER(@genero),
        EncryptByKey(Key_GUID('LlaveSimetrica'), @cuil),
        HASHBYTES('SHA2_512', @cuil),
		EncryptByKey(Key_GUID('LlaveSimetrica'), @telefono),
        EncryptByKey(Key_GUID('LlaveSimetrica'), @domicilio),
		ISNULL(@fechaAlta,GETDATE()),
        EncryptByKey(Key_GUID('LlaveSimetrica'), LOWER(@mailPersonal)),
		LOWER(@mailEmpresa),
		@idCargo,
        @idSucursal,
		@idTurno
    );
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Empresa.ActualizarEmpleado_sp
    @legajo         INT,
    @nombre			VARCHAR(30) = NULL,
    @apellido		VARCHAR(30) = NULL,
    @genero			VARCHAR(25) = NULL,
    @cuil			VARCHAR(25) = NULL,
    @telefono		VARCHAR(25) = NULL,
    @domicilio		NVARCHAR(100) = NULL,
    @fechaAlta		DATE = NULL,
    @mailPersonal	VARCHAR(55) = NULL,
    @mailEmpresa	VARCHAR(55) = NULL,
    @cargo          VARCHAR(20) = NULL,
    @sucursal       VARCHAR(25) = NULL,
    @turno          VARCHAR(25) = NULL,
    @nuevoLegajo    VARCHAR(25) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @idCargo    INT,
            @idSucursal INT,
            @idTurno    INT;

    IF @nombre IS NULL AND @apellido IS NULL AND @genero IS NULL AND @cuil IS NULL AND @telefono IS NULL AND @domicilio IS NULL AND @fechaAlta IS NULL
       AND @mailPersonal IS NULL AND @mailEmpresa IS NULL AND @cargo IS NULL AND @sucursal IS NULL AND @turno IS NULL AND @nuevoLegajo IS NULL
    BEGIN
        RAISERROR('Debe indicar al menos un cambio.', 16, 1);
		RETURN;
    END

    IF @legajo <= 0
    BEGIN
		RAISERROR('El formato de legajo es inválido.',16,1)
		RETURN;
	END

    IF NOT EXISTS (SELECT 1 FROM Empresa.Empleado WHERE legajo = @legajo AND activo = 1)
    BEGIN
		RAISERROR('El empleado no existe o no se encuentra activo.', 16, 1);
	END

    IF @cuil IS NOT NULL AND Utilidades.ValidarCuil(@cuil) = 0
	BEGIN
		RAISERROR('El formato de cuil es inválido.',16,1)
		RETURN;
	END
	
	IF EXISTS (SELECT 1 FROM Empresa.Empleado WHERE cuilHASH = HASHBYTES('SHA2_512', @cuil))
    BEGIN
		RAISERROR('Ya existe un empleado con el nuevo CUIL.', 16, 1);
        RETURN;
	END

    IF LEN(LTRIM(RTRIM(@nombre))) = 0
    BEGIN
         RAISERROR('El nuevo nombre del empleado no puede estar vacío.', 16, 1);
         RETURN;
    END

    IF LEN(LTRIM(RTRIM(@apellido))) = 0
    BEGIN
         RAISERROR('El nuevo apellido del empleado no puede estar vacío.', 16, 1);
         RETURN;
    END

	IF UPPER(@genero) NOT IN ('M', 'F')
	BEGIN
		RAISERROR('El formato del nuevo género es inválido.',16,1)
		RETURN;
	END
	
	IF @telefono NOT LIKE '11[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
	BEGIN
		RAISERROR('El formato del nuevo teléfono es inválido.', 16, 1);
		RETURN;
	END

    IF LEN(LTRIM(RTRIM(@domicilio))) = 0
    BEGIN
         RAISERROR('El nuevo domicilio del empleado no puede estar vacío.', 16, 1);
         RETURN;
    END

	IF @mailPersonal NOT LIKE '_%@_%._%' 
	BEGIN
		RAISERROR('El formato del nuevo mail personal es inválido.', 16, 1);
		RETURN;
	END

	IF LOWER(@mailEmpresa) NOT LIKE '_%@aurorasa.com.ar' 
	BEGIN
		RAISERROR('El formato del nuevo mail de la empresa es inválido.', 16, 1);
		RETURN;
	END

    SET @idCargo = (SELECT idCargo FROM Empresa.Cargo WHERE nombre = @cargo AND activo = 1)
    IF @idCargo IS NULL AND @cargo IS NOT NULL
    BEGIN
	    RAISERROR('El nuevo cargo no existe o no está activo.', 16, 1);
        RETURN;
    END

    IF @sucursal NOT LIKE '[A-Z][A-Z][0-9]'
    BEGIN
        RAISERROR('El formato de la nueva sucursal es inválido', 16, 1);
        RETURN;
    END

    SET @idSucursal = (SELECT idSucursal FROM Empresa.Sucursal WHERE codigoSucursal = @sucursal AND activo = 1)
    IF @idSucursal IS NULL AND @sucursal IS NOT NULL
    BEGIN
	    RAISERROR('La nueva sucursal no existe o no está activa.', 16, 1);
        RETURN;
    END

    IF @turno NOT LIKE '[A-Z][A-Z]'
    BEGIN
        RAISERROR('El formato del nuevo turno es inválido', 16, 1);
        RETURN;
    END

    SET @idTurno = (SELECT idTurno FROM Empresa.Turno WHERE acronimo = @turno AND activo = 1)
    IF @idTurno IS NULL AND @turno IS NOT NULL
    BEGIN
	    RAISERROR('El nuevo turno no existe o no está activo.', 16, 1);
        RETURN;
    END

    IF @nuevoLegajo IS NOT NULL AND @nuevoLegajo <> @legajo
    BEGIN
        IF @legajo <= 0
        BEGIN
		    RAISERROR('El formato del nuevo legajo es inválido.',16,1)
		    RETURN;
	    END

        IF EXISTS (SELECT 1 FROM Empresa.Empleado WHERE legajo = @legajo)
        BEGIN
		    RAISERROR('El nuevo legajo ya está en uso.', 16, 1);
            RETURN;
	    END
    END

    UPDATE Empresa.Empleado
    SET legajo       = ISNULL(@nuevoLegajo, legajo),
        nombre	     = ISNULL(@nombre, nombre),
        apellido     = ISNULL(@apellido, apellido),
		genero	     = ISNULL(UPPER(@genero), genero),
		cuil	     = ISNULL(EncryptByKey(Key_GUID('LlaveSimetrica'), @cuil), cuil),
        cuilHASH     = ISNULL(HASHBYTES('SHA2_512', @cuil), cuilHASH),
        telefono     = ISNULL(EncryptByKey(Key_GUID('LlaveSimetrica'), @telefono), telefono),
		domicilio    = ISNULL(EncryptByKey(Key_GUID('LlaveSimetrica'), @domicilio), domicilio),
		fechaAlta    = ISNULL(@fechaAlta, fechaAlta),
		mailPersonal = ISNULL(EncryptByKey(Key_GUID('LlaveSimetrica'), LOWER(@mailPersonal)), mailPersonal),
		mailEmpresa  = ISNULL(LOWER(@mailEmpresa), mailEmpresa),
        idCargo      = ISNULL(@idCargo, idCargo),
		idSucursal   = ISNULL(@idSucursal, idSucursal),
		idTurno	     = ISNULL(@idTurno, idTurno)
    WHERE legajo = @legajo;
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Empresa.EliminarEmpleado_sp
    @legajo INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @legajo <= 0
    BEGIN
	    RAISERROR('El formato del legajo es inválido.',16,1)
	    RETURN;
	END

    IF NOT EXISTS (SELECT 1 FROM Empresa.Empleado WHERE legajo = @legajo AND activo = 1)
    BEGIN
	    RAISERROR('El empleado no existe o no se encuentra activo.', 16, 1);
        RETURN;
	END

    UPDATE Empresa.Empleado
    SET activo = 0
    WHERE legajo = @legajo;
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Empresa.ReactivarEmpleado_sp
    @legajo INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @legajo <= 0
    BEGIN
	    RAISERROR('El formato del legajo es inválido.',16,1)
	    RETURN;
	END

    IF NOT EXISTS (SELECT 1 FROM Empresa.Empleado WHERE legajo = @legajo AND activo = 0)
    BEGIN
	    RAISERROR('El empleado no existe o ya se encuentra activo.', 16, 1);
        RETURN;
	END

    UPDATE Empresa.Empleado
    SET activo = 1
    WHERE legajo = @legajo;
END;
GO

----------------------------------------------------------------------------------------------
-- ABM Inventario.LineaProducto
CREATE PROCEDURE Inventario.InsertarLineaProducto_sp
    @descripcion VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;

    IF LEN(LTRIM(RTRIM(@descripcion))) = 0
    BEGIN
         RAISERROR('La descripción de la linea de producto no puede estar vacía.', 16, 1);
         RETURN;
    END

	IF EXISTS (SELECT 1 FROM Inventario.LineaProducto WHERE descripcion = @descripcion) 
	BEGIN
        RAISERROR('La linea de producto ya existe.', 16, 1);
		RETURN;
	END

	INSERT INTO Inventario.LineaProducto (descripcion)
	VALUES (@descripcion);
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Inventario.ActualizarLineaProducto_sp
    @descripcion      VARCHAR(30),
    @nuevaDescripcion VARCHAR(30) = NULL,
    @activo           BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @nuevaDescripcion IS NULL AND @activo IS NULL
    BEGIN
        RAISERROR('Debe indicar al menos un cambio.', 16, 1);
		RETURN;
    END

	IF NOT EXISTS (SELECT 1 FROM Inventario.LineaProducto WHERE descripcion = @descripcion AND activo = 1)
	BEGIN
		RAISERROR('La linea de producto no existe o no se encuentra activa.',16,1);
		RETURN;
	END

    IF @nuevaDescripcion IS NOT NULL AND @nuevaDescripcion <> @descripcion
    BEGIN
    	IF LEN(LTRIM(RTRIM(@nuevaDescripcion))) = 0
        BEGIN
            RAISERROR('La descripción de la nueva linea de producto no puede estar vacía.', 16, 1);
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM Inventario.LineaProducto WHERE descripcion = @nuevaDescripcion)
        BEGIN
		    RAISERROR('La nueva linea de producto ya existe.',16,1);
		    RETURN;
    	END
    END

	UPDATE Inventario.LineaProducto
	SET descripcion = ISNULL(@nuevaDescripcion, descripcion)
	WHERE descripcion = @descripcion;
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Inventario.EliminarLineaProducto_sp
	@descripcion VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;

	IF NOT EXISTS (SELECT 1 FROM Inventario.LineaProducto WHERE descripcion = @descripcion AND activo = 1)
	BEGIN
		RAISERROR('La linea de producto no existe o no se encuentra activa.',16,1);
		RETURN;
	END

	UPDATE Inventario.LineaProducto
	SET activo = 0
	WHERE descripcion = @descripcion;
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Inventario.ReactivarLineaProducto_sp
	@descripcion VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;

	IF NOT EXISTS (SELECT 1 FROM Inventario.LineaProducto WHERE descripcion = @descripcion AND activo = 0)
	BEGIN
		RAISERROR('La linea de producto no existe o ya se encuentra activa.',16,1);
		RETURN;
	END

	UPDATE Inventario.LineaProducto
	SET activo = 1
	WHERE descripcion = @descripcion;
END;
GO

----------------------------------------------------------------------------------------------
-- ABM Inventario.Producto	
CREATE PROCEDURE Inventario.InsertarProducto_sp
    @nombreProducto   NVARCHAR(100),
    @precioUnitario   DECIMAL(10,2),
    @lineaProducto    VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @idLinea INT

    IF LEN(LTRIM(RTRIM(@nombreProducto))) = 0
    BEGIN
         RAISERROR('El nombre del producto no puede estar vacío.', 16, 1);
         RETURN;
    END

    IF EXISTS (SELECT 1 FROM Inventario.Producto WHERE nombreProducto = @nombreProducto)
    BEGIN
		RAISERROR('El producto ya existe.', 16, 1);
		RETURN;
	END
    
    --Verificar linea de producto
    SET @idLinea = (SELECT idLineaProd FROM Inventario.LineaProducto WHERE descripcion = @lineaProducto AND activo = 1)
	IF @idLinea IS NULL
	BEGIN
		RAISERROR('La linea de producto no existe o no esta activa.', 16, 1);
		RETURN;
	END

    IF @precioUnitario <= 0
	BEGIN
        RAISERROR('El precio unitario debe ser mayor a 0.', 16, 1);
     	RETURN;
	END

    INSERT INTO Inventario.Producto (
        nombreProducto,
        precioUnitario,
		idLineaProducto
    )
    VALUES (
        @nombreProducto,
        @precioUnitario,
		@idLinea 
    );
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Inventario.ActualizarProducto_sp
    @nombreProducto   NVARCHAR(100),
    @lineaProducto    VARCHAR(30) = NULL,
    @precioUnitario   DECIMAL(10,2) = NULL,
    @nuevoNombreProd  NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @idLinea INT

    IF @lineaProducto IS NULL AND @precioUnitario IS NULL AND @nuevoNombreProd IS NULL
    BEGIN
        RAISERROR('Debe indicar al menos un cambio.', 16, 1);
		RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Inventario.Producto WHERE nombreProducto = @nombreProducto AND activo = 1)
    BEGIN
		RAISERROR('El producto no existe o no se encuentra activo.', 16, 1);
		RETURN;
	END
    
    SET @idLinea = (SELECT idLineaProd FROM Inventario.LineaProducto WHERE descripcion = @lineaProducto AND activo = 1)
	IF @idLinea IS NULL AND @lineaProducto IS NOT NULL
	BEGIN
		RAISERROR('La nueva linea de producto no existe o no esta activa.', 16, 1);
		RETURN;
	END

    IF @precioUnitario <= 0
	BEGIN
        RAISERROR('El nuevo precio unitario debe ser mayor a 0.', 16, 1);
     	RETURN;
	END

    IF @nuevoNombreProd IS NOT NULL AND @nuevoNombreProd <> @nombreProducto
    BEGIN
        IF LEN(LTRIM(RTRIM(@nuevoNombreProd))) = 0
        BEGIN
             RAISERROR('El nuevo nombre del producto no puede estar vacío.', 16, 1);
             RETURN;
        END

        IF EXISTS (SELECT 1 FROM Inventario.Producto WHERE nombreProducto = @nuevoNombreProd)
        BEGIN
            RAISERROR('El nuevo nombre del producto ya existe.', 16, 1);
            RETURN;
        END
    END

	
    UPDATE Inventario.Producto
    SET nombreProducto  = ISNULL(@nuevoNombreProd, nombreProducto),
        idLineaProducto   = ISNULL(@idLinea,idLineaProducto), 
        precioUnitario  = ISNULL(@precioUnitario, precioUnitario)
    WHERE nombreProducto = @nombreProducto;
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Inventario.EliminarProducto_sp
    @nombreProducto   NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Inventario.Producto WHERE nombreProducto = @nombreProducto AND activo = 1)
	BEGIN
        RAISERROR('El producto no existe o no se encuentra activo.', 16, 1);
		RETURN;
	END
      
    UPDATE Inventario.Producto
    SET activo = 0
    WHERE nombreProducto = @nombreProducto;
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Inventario.ReactivarProducto_sp
    @nombreProducto   NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Inventario.Producto WHERE nombreProducto = @nombreProducto AND activo = 0)
	BEGIN
        RAISERROR('El producto no existe o ya se encuentra activo.', 16, 1);
		RETURN;
	END
      
    UPDATE Inventario.Producto
    SET activo = 1
    WHERE nombreProducto = @nombreProducto;
END;
GO

----------------------------------------------------------------------------------------------
-- ABM Ventas.Cliente
CREATE PROCEDURE Ventas.InsertarCliente_sp
    @dni                VARCHAR(25),
    @nombre				VARCHAR(30),
    @apellido			VARCHAR(30),
    @genero				VARCHAR(25),
    @tipoCliente		VARCHAR(10),
    @puntos             INT = NULL,
    @fechaAlta          DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @dni NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' AND @dni <> '0' --Reservado para clientes sin registrar
    BEGIN
		RAISERROR('El formato del dni es inválido.',16,1)
		RETURN;
	END

    IF EXISTS (SELECT 1 FROM Ventas.Cliente WHERE dniHASH = HASHBYTES('SHA2_256', @dni))
	BEGIN
		RAISERROR('El cliente ya existe.',16,1)
		RETURN;
	END

    IF LEN(LTRIM(RTRIM(@nombre))) = 0
    BEGIN
        RAISERROR('El nombre del cliente no puede estar vacío.', 16, 1);
        RETURN;
    END

    IF LEN(LTRIM(RTRIM(@apellido))) = 0
    BEGIN
        RAISERROR('El apellido del cliente no puede estar vacío.', 16, 1);
        RETURN;
    END

	IF UPPER(@genero) NOT IN ('M', 'F')
	BEGIN
		RAISERROR('El formato del género es inválido.',16,1)
		RETURN;
	END

    IF @tipoCliente NOT IN ('Normal','Miembro')
	BEGIN
		RAISERROR('El tipo de cliente es inválido.',16,1)
		RETURN;
	END

    IF @puntos < 0
	BEGIN
		RAISERROR('Los puntos deben ser mayores o iguales a cero.',16,1)
		RETURN;
	END

    IF @tipoCliente = 'Normal'
    BEGIN
        IF @puntos IS NOT NULL AND @puntos <> 0
        BEGIN
		    RAISERROR('Un cliente no miembro no puede tener puntos.',16,1)
		    RETURN;
	    END

        SET @puntos = NULL
    END

    IF @tipoCliente = 'Miembro' AND @puntos IS NULL
        SET @puntos = 0


	INSERT INTO Ventas.Cliente (
        nombre,
        apellido,
        dni,
        dniHASH,
        genero,
        tipoCliente,
        puntos,
        fechaAlta
    )
    VALUES (
		@nombre,	
		@apellido,
        EncryptByKey(Key_GUID('LlaveSimetrica'), @dni),
        HASHBYTES('SHA2_256', @dni),
        UPPER(@genero),
		@tipoCliente,
		@puntos,
        ISNULL(@fechaAlta,GETDATE())
    );

END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Ventas.ActualizarCliente_sp
    @dni                VARCHAR(25),
    @nombre				VARCHAR(30) = NULL,
    @apellido			VARCHAR(30) = NULL,
    @genero				VARCHAR(25) = NULL,
    @tipoCliente		VARCHAR(10) = NULL,
    @puntos             INT = NULL,
    @fechaAlta          DATETIME = NULL,
    @nuevoDni           VARCHAR(25) = NULL
   
AS
BEGIN
    SET NOCOUNT ON;

    IF @nombre IS NULL AND @apellido IS NULL AND @genero IS NULL AND @tipoCliente IS NULL AND @puntos IS NULL AND @fechaAlta IS NULL AND @nuevoDni IS NULL
    BEGIN
        RAISERROR('Debe indicar al menos un cambio.', 16, 1);
		RETURN;
    END

    IF @dni NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
    BEGIN
		RAISERROR('El formato del dni es inválido.',16,1)
		RETURN;
	END

    IF NOT EXISTS (SELECT 1 FROM Ventas.Cliente WHERE dniHASH = HASHBYTES('SHA2_256', @dni) AND activo = 1)
	BEGIN
        RAISERROR('El cliente no existe o no se encuentra activo.', 16, 1);
		RETURN;
	END

    IF LEN(LTRIM(RTRIM(@nombre))) = 0
    BEGIN
        RAISERROR('El nuevo nombre del cliente no puede estar vacío.', 16, 1);
        RETURN;
    END

    IF LEN(LTRIM(RTRIM(@apellido))) = 0
    BEGIN
        RAISERROR('El nuevo apellido del cliente no puede estar vacío.', 16, 1);
        RETURN;
    END

	IF UPPER(@genero) NOT IN ('M', 'F')
	BEGIN
		RAISERROR('El formato del género es inválido.',16,1)
		RETURN;
	END

    IF @tipoCliente NOT IN ('Normal','Miembro')
	BEGIN
		RAISERROR('El tipo de cliente es inválido.',16,1)
		RETURN;
	END

    IF @puntos < 0
	BEGIN
		RAISERROR('Los puntos deben ser mayores o iguales a cero.',16,1)
		RETURN;
	END

    IF @tipoCliente = 'Normal'
    BEGIN
        IF @puntos IS NOT NULL AND @puntos <> 0
        BEGIN
		    RAISERROR('Un cliente no miembro no puede tener puntos.',16,1)
		    RETURN;
	    END

        SET @puntos = NULL
    END

    IF @tipoCliente = 'Miembro' AND @puntos IS NULL
        SET @puntos = 0

    IF @nuevoDni IS NOT NULL AND @nuevoDni <> @dni
    BEGIN
        IF @nuevoDni NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
        BEGIN
		    RAISERROR('El formato del nuevo dni es inválido.',16,1)
		    RETURN;
	    END

        IF EXISTS (SELECT 1 FROM Ventas.Cliente WHERE dniHASH = HASHBYTES('SHA2_256', @nuevoDni))
	    BEGIN
		    RAISERROR('El nuevo dni ya está en uso.',16,1)
		    RETURN;
	    END 
    END

    UPDATE Ventas.Cliente
    SET nombre		= ISNULL(@nombre, nombre),
        apellido	= ISNULL(@apellido, apellido),
        dni         = ISNULL(EncryptByKey(Key_GUID('LlaveSimetrica'), @nuevoDni), dni),
        dniHASH     = ISNULL(HASHBYTES('SHA2_256', @nuevoDni), dniHASH),
        genero		= ISNULL(@genero, genero),
        tipoCliente	= ISNULL(@tipoCliente, tipoCliente),
		puntos      = ISNULL(@puntos, puntos),
        fechaAlta   = ISNULL(@fechaAlta, fechaAlta)
    WHERE dniHASH = HASHBYTES('SHA2_256', @dni);
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Ventas.EliminarCliente_sp
    @dni VARCHAR(25)
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @dni NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
    BEGIN
		RAISERROR('El formato del dni es inválido.',16,1)
		RETURN;
	END

    IF NOT EXISTS (SELECT 1 FROM Ventas.Cliente WHERE dniHASH = HASHBYTES('SHA2_256', @dni) AND activo = 1)
	BEGIN
        RAISERROR('El cliente no existe o no se encuentra activo.', 16, 1);
		RETURN;
	END

    -- Borrado lógico
    UPDATE Ventas.Cliente
    SET activo = 0
    WHERE dniHASH = HASHBYTES('SHA2_256', @dni);
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Ventas.ReactivarCliente_sp
    @dni VARCHAR(25)
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @dni NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
    BEGIN
		RAISERROR('El formato del dni es inválido.',16,1)
		RETURN;
	END

    IF NOT EXISTS (SELECT 1 FROM Ventas.Cliente WHERE dniHASH = HASHBYTES('SHA2_256', @dni) AND activo = 0)
	BEGIN
        RAISERROR('El cliente no existe o ya se encuentra activo.', 16, 1);
		RETURN;
	END

    -- Borrado lógico
    UPDATE Ventas.Cliente
    SET activo = 1
    WHERE dniHASH = HASHBYTES('SHA2_256', @dni);
END;
GO
----------------------------------------------------------------------------------------------
-- ABM Ventas.MedioPago
CREATE PROCEDURE Ventas.InsertarMedioPago_sp
    @nombre      NVARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;

    IF LEN(LTRIM(RTRIM(@nombre))) = 0
    BEGIN
         RAISERROR('El nombre del medio de pago no puede estar vacío.', 16, 1);
         RETURN;
    END

    IF EXISTS (SELECT 1 FROM Ventas.MedioPago WHERE nombre = @nombre)
	BEGIN
        RAISERROR('El medio de pago ya existe.', 16, 1);
		RETURN;
	END

    INSERT INTO Ventas.MedioPago (nombre)
    VALUES (@nombre);
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Ventas.ActualizarMedioPago_sp
    @nombre      NVARCHAR(30),
    @nuevoNombre NVARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Ventas.MedioPago WHERE nombre = @nombre AND activo = 1)
	BEGIN
        RAISERROR('El medio de pago no existe o no se encuentra activo.', 16, 1);
		RETURN;
	END

    IF LEN(LTRIM(RTRIM(@nuevoNombre))) = 0
    BEGIN
        RAISERROR('El nuevo nombre del medio de pago no puede estar vacío.', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM Ventas.MedioPago WHERE nombre = @nuevoNombre)
    BEGIN
        RAISERROR('El nuevo nombre del medio de pago ya está en uso.', 16, 1);
        RETURN;
    END
    
    UPDATE Ventas.MedioPago
    SET nombre   = @nuevoNombre
    WHERE nombre = @nombre;
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Ventas.EliminarMedioPago_sp
	@nombre NVARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;

	IF NOT EXISTS (SELECT 1 FROM Ventas.MedioPago WHERE nombre = @nombre AND activo = 1)
	BEGIN
		RAISERROR('El medio de pago no existe o no se encuentra activo.',16,1);
		RETURN;
	END

	UPDATE Ventas.MedioPago
	SET activo = 0
	WHERE nombre = @nombre;
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Ventas.ReactivarMedioPago_sp
	@nombre NVARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;

	IF NOT EXISTS (SELECT 1 FROM Ventas.MedioPago WHERE nombre = @nombre AND activo = 0)
	BEGIN
		RAISERROR('El medio de pago no existe o ya se encuentra activo.',16,1);
		RETURN;
	END

	UPDATE Ventas.MedioPago
	SET activo = 1
	WHERE nombre = @nombre;
END;
GO

----------------------------------------------------------------------------------------------
-- ABM Ventas.Factura
CREATE PROCEDURE Ventas.InsertarFactura_sp
    @codigoFactura		VARCHAR(25),
	@tipoFactura		VARCHAR(25),
    @fecha				DATETIME = NULL,
    @medioPago			NVARCHAR(20),
    @detallesPago       VARCHAR(100) = NULL,
	@cliente		    VARCHAR(25),
    @empleado			INT,
    @sucursal			VARCHAR(25)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @idMedio    INT,
            @idCliente  INT,
            @idSucursal	INT,
            @idEmpleado INT;

    IF @codigoFactura NOT LIKE ('[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]')
	BEGIN
		RAISERROR('El formato de codigo de factura es inválido.',16,1);
		RETURN;
	END

    IF EXISTS (SELECT 1 FROM Ventas.Factura WHERE codigoFactura = @codigoFactura)
    BEGIN
		RAISERROR('La factura ya existe.',16,1);
		RETURN;
	END

    IF @tipoFactura NOT IN ('A','B','C')
	BEGIN
        RAISERROR('El tipo de factura es inválido (use A, B o C).', 16, 1);
		RETURN;
	END

    SET @idMedio = (SELECT idMedio FROM Ventas.MedioPago WHERE nombre = @medioPago AND activo = 1)
    IF @idMedio IS NULL
    BEGIN
	    RAISERROR('El medio de pago no existe o no se encuentra activo.', 16, 1);
        RETURN;
    END
 
    IF @empleado <= 0
	BEGIN
		RAISERROR('El formato del legajo de empleado es inválido.',16,1)
		RETURN;
	END

    SET @idEmpleado = (SELECT idEmpleado FROM Empresa.Empleado WHERE legajo = @empleado AND activo = 1)
    IF @idEmpleado IS NULL
    BEGIN
	    RAISERROR('El empleado no existe o no se enecuentra activo.', 16, 1);
        RETURN;
    END

    IF @cliente NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
	BEGIN
		RAISERROR('El formato del dni del cliente es inválido.',16,1)
		RETURN;
	END

    SET @idCliente = (SELECT idCliente FROM Ventas.Cliente WHERE dniHASH = HASHBYTES('SHA2_256', @cliente) AND activo = 1)
    IF @idCliente IS NULL
    BEGIN
	    RAISERROR('El cliente no existe o no se enecuentra activo.', 16, 1);
        RETURN;
    END

    IF @sucursal NOT LIKE '[A-Z][A-Z][0-9]'
    BEGIN
        RAISERROR('El formato de la sucursal es inválido', 16, 1);
        RETURN;
    END

    SET @idSucursal = (SELECT idSucursal FROM Empresa.Sucursal WHERE codigoSucursal = @sucursal AND activo = 1)
    IF @idSucursal IS NULL
    BEGIN
	    RAISERROR('La sucursal no existe o no se enecuentra activa.', 16, 1);
        RETURN;
    END


    INSERT INTO Ventas.Factura (
        codigoFactura,
		tipoFactura,
        fecha,
        idMedioPago,
		detallesPago,
        idCliente,
        idEmpleado,
        idSucursal
    )
    VALUES (
        @codigoFactura,
		@tipoFactura,
        ISNULL(@fecha, GETDATE()),
        @idMedio,
		@detallesPago,
		@idCliente,
        @idEmpleado,
        @idSucursal
    );
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Ventas.ActualizarFactura_sp
    @codigoFactura		VARCHAR(25),
	@tipoFactura		VARCHAR(25) = NULL,
    @fecha				DATETIME = NULL,
    @medioPago			NVARCHAR(20) = NULL,
    @detallesPago       VARCHAR(100) = NULL,
	@cliente		    VARCHAR(25) = NULL,
    @empleado			INT = NULL,
    @sucursal			VARCHAR(25) = NULL,
    @nuevoCodigo        VARCHAR(25) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @idMedio    INT,
            @idCliente  INT,
            @idSucursal INT,
            @idEmpleado INT;

    IF @tipoFactura IS NULL AND @fecha IS NULL AND @medioPago IS NULL AND @detallesPago IS NULL AND @cliente IS NULL AND @empleado IS NULL AND @sucursal IS NULL AND @nuevoCodigo IS NULL  
    BEGIN
		RAISERROR('Debe indicar al menos un cambio.', 16, 1);
		RETURN;
	END

    IF @codigoFactura NOT LIKE ('[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]')
	BEGIN
		RAISERROR('El formato de codigo de factura es inválido.',16,1);
		RETURN;
	END

    IF NOT EXISTS (SELECT 1 FROM Ventas.Factura WHERE codigoFactura = @codigoFactura AND activo = 1)
    BEGIN
		RAISERROR('La factura no existe o no se encuentra activa.',16,1);
		RETURN;
	END

    IF @tipoFactura NOT IN ('A','B','C')
	BEGIN
        RAISERROR('El nuevo tipo de factura es inválido (use A, B o C).', 16, 1);
		RETURN;
	END

    SET @idMedio = (SELECT idMedio FROM Ventas.MedioPago WHERE nombre = @medioPago AND activo = 1)
    IF @idMedio IS NULL AND @medioPago IS NOT NULL
    BEGIN
	    RAISERROR('El nuevo medio de pago no existe o no se encuentra activo.', 16, 1);
        RETURN;
    END
 
    IF @empleado <= 0
	BEGIN
		RAISERROR('El formato del legajo del empleado es inválido.',16,1)
		RETURN;
	END

    SET @idEmpleado = (SELECT idEmpleado FROM Empresa.Empleado WHERE legajo = @empleado AND activo = 1)
    IF @idEmpleado IS NULL AND @empleado IS NOT NULL
    BEGIN
	    RAISERROR('El nuevo empleado no existe o no se enecuentra activo.', 16, 1);
        RETURN;
    END

    IF @cliente NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
	BEGIN
		RAISERROR('El formato del nuevo dni del cliente es inválido.',16,1)
		RETURN;
	END

    SET @idCliente = (SELECT idCliente FROM Ventas.Cliente WHERE dniHASH = HASHBYTES('SHA2_256', @cliente) AND activo = 1)
    IF @idCliente IS NULL AND @cliente IS NOT NULL
    BEGIN
	    RAISERROR('El nuevo cliente no existe o no se enecuentra activo.', 16, 1);
        RETURN;
    END

    IF @sucursal NOT LIKE '[A-Z][A-Z][0-9]'
    BEGIN
        RAISERROR('El formato de la nueva sucursal es inválido', 16, 1);
        RETURN;
    END

    SET @idSucursal = (SELECT idSucursal FROM Empresa.Sucursal WHERE codigoSucursal = @sucursal AND activo = 1)
    IF @idSucursal IS NULL AND @sucursal IS NOT NULL
    BEGIN
	    RAISERROR('La nueva sucursal no existe o no se enecuentra activa.', 16, 1);
        RETURN;
    END

    IF @nuevoCodigo IS NOT NULL AND @nuevoCodigo <> @codigoFactura
    BEGIN
        IF @nuevoCodigo NOT LIKE ('[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]')
	    BEGIN
		    RAISERROR('El formato del nuevo código de factura es inválido.',16,1);
		    RETURN;
        END;

        IF EXISTS (SELECT 1 FROM Ventas.Factura WHERE codigoFactura = @nuevoCodigo)
        BEGIN
		    RAISERROR('El nuevo código de factura ya está en uso.',16,1);
		    RETURN;
	    END

        -- El id se mantiene, no es necesario actualizar Ventas.DetalleVentas
    END

    UPDATE Ventas.Factura
    SET codigoFactura	  = ISNULL(@nuevoCodigo, codigoFactura),
		tipoFactura		  = ISNULL(@tipoFactura, tipoFactura),
        fecha			  = ISNULL(@fecha, fecha),
        idMedioPago		  = ISNULL(@medioPago, idMedioPago),
		detallesPago      = ISNULL(@detallesPago, detallesPago),
        idCliente		  = ISNULL(@idCliente, idCliente),
        idEmpleado		  = ISNULL(@idEmpleado, idEmpleado),
        idSucursal		  = ISNULL(@idSucursal, idSucursal)
    WHERE codigoFactura = @codigoFactura;
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Ventas.EliminarFactura_sp
    @codigoFactura VARCHAR(25)
AS
BEGIN
    SET NOCOUNT ON;

    IF @codigoFactura NOT LIKE ('[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]')
	BEGIN
		RAISERROR('El formato de codigo de factura es inválido.',16,1);
		RETURN;
	END

    IF NOT EXISTS (SELECT 1 FROM Ventas.Factura WHERE codigoFactura = @codigoFactura AND activo = 1)
	BEGIN
        RAISERROR('No existe la factura indicada o no se encuentra activa.', 16, 1);
    	RETURN;
	END

    UPDATE Ventas.Factura
    SET activo = 0
    WHERE codigoFactura = @codigoFactura;
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Ventas.ReactivarFactura_sp
    @codigoFactura VARCHAR(25)
AS
BEGIN
    SET NOCOUNT ON;

    IF @codigoFactura NOT LIKE ('[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]')
	BEGIN
		RAISERROR('El formato de codigo de factura es inválido.',16,1);
		RETURN;
	END

    IF NOT EXISTS (SELECT 1 FROM Ventas.Factura WHERE codigoFactura = @codigoFactura AND activo = 0)
	BEGIN
        RAISERROR('No existe la factura indicada o ya se encuentra activa.', 16, 1);
    	RETURN;
	END

    UPDATE Ventas.Factura
    SET activo = 1
    WHERE codigoFactura = @codigoFactura;
END;
GO

----------------------------------------------------------------------------------------------
-- ABM Ventas.DetalleFactura
CREATE PROCEDURE Ventas.InsertarDetalleFactura_sp
    @codigoFactura  VARCHAR(25),
    @producto       NVARCHAR(100),
    @cantidad       INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @idFactura      INT,
            @idProducto     INT,
            @idDetalleFactura INT,
            @precioUnitario DECIMAL(10,2);

    IF @codigoFactura NOT LIKE ('[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]')
	BEGIN
		RAISERROR('El formato de codigo de factura es inválido.',16,1);
		RETURN;
	END

    SET @idFactura = (SELECT idFactura FROM Ventas.Factura WHERE codigoFactura = @codigoFactura AND activo = 1)
    IF @idFactura IS NULL
	BEGIN
        RAISERROR('No existe la factura indicada o no se encuentra activa.', 16, 1);
    	RETURN;
	END

    SET @idProducto = (SELECT idProducto FROM Inventario.Producto WHERE nombreProducto = @producto AND activo = 1)
    IF @idProducto IS NULL
    BEGIN
	    RAISERROR('El producto no existe o no se encuentra activo.', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM Ventas.DetalleFactura WHERE idFactura = @idFactura AND idProducto = @idProducto)
    BEGIN
        RAISERROR('Ya existe un detalle de factura con el producto ingresado.', 16, 1);
    	RETURN;
    END

	IF @cantidad <= 0
	BEGIN
        RAISERROR('La cantidad debe ser mayor a 0.', 16, 1);
		RETURN;
	END

	-- Guardado de precio del producto al momento de la factura
	SET @precioUnitario = (SELECT precioUnitario from Inventario.Producto WHERE idProducto = @idProducto);
	
	-- Crear el idDetalle para que sea consecutivo al ultimo numero correspondiente a la factura accedida 
    SET @idDetalleFactura = ISNULL((SELECT MAX(idDetalleFactura) FROM Ventas.DetalleFactura WHERE idFactura = @idFactura), 0) + 1;

    INSERT INTO Ventas.DetalleFactura (
        idFactura,
		idDetalleFactura,
        idProducto,
        cantidad,
        precioUnitario,
        subtotal
    )
    VALUES (
        @idFactura,
		@idDetalleFactura,
        @idProducto,
        @cantidad,
        @precioUnitario,
        (@cantidad * @precioUnitario)  -- Calculamos subtotal
    );

    -- Actualizar Venta.Factura
    UPDATE Ventas.Factura
    SET total = total + (@cantidad * @precioUnitario)
    WHERE idFactura = @idFactura;
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Ventas.ActualizarDetalleFactura_sp
    @codigoFactura  VARCHAR(25),
    @numDetalle     INT,
    @producto       NVARCHAR(100) = NULL,
    @precioUnitario DECIMAL(10,2) = NULL,
    @cantidad       INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @idFactura			INT,
            @idProducto			INT,
            @idDetalleFactura	INT,
			@totalSinDetalle	DECIMAL(10,2);

    IF @producto IS NULL AND @precioUnitario IS NULL AND  @cantidad IS NULL
    BEGIN
        RAISERROR('Debe indicar al menos un cambio.', 16, 1);
		RETURN;
	END

    IF @codigoFactura NOT LIKE ('[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]')
	BEGIN
		RAISERROR('El formato de codigo de factura es inválido.',16,1);
		RETURN;
	END

    SET @idFactura = (SELECT idFactura FROM Ventas.Factura WHERE codigoFactura = @codigoFactura AND activo = 1)
    IF @idFactura IS NULL
	BEGIN
        RAISERROR('No existe la factura indicada o no se encuentra activa.', 16, 1);
    	RETURN;
	END

    IF NOT EXISTS (SELECT 1 FROM Ventas.DetalleFactura WHERE idFactura = @idFactura AND idDetalleFactura = @numDetalle)
	BEGIN
        RAISERROR('No existe el numero de detalle de la factura indicada.', 16, 1);
    	RETURN;
	END

	SET @idProducto = (SELECT idProducto FROM Inventario.Producto WHERE nombreProducto = @producto AND activo = 1)
    IF @idProducto IS NULL AND @producto IS NOT NULL
    BEGIN
	    RAISERROR('El producto no existe o no se encuentra activo.', 16, 1);
        RETURN;
    END

	IF EXISTS (SELECT 1 FROM Ventas.DetalleFactura WHERE idFactura = @idFactura AND idProducto = @idProducto AND idDetalleFactura <> @numDetalle)
    BEGIN
        RAISERROR('Ya existe un detalle de esta factura con el producto ingresado.', 16, 1);
    	RETURN;
    END

	IF @cantidad <= 0
	BEGIN
        RAISERROR('La cantidad debe ser mayor a 0.', 16, 1);
		RETURN;
	END

	IF @precioUnitario <= 0 
	BEGIN
        RAISERROR('El precio unitario debe ser mayor a 0.', 16, 1);
		RETURN;
	END

    -- Se guarda el total de la factura sin incluir el detalle actualizado (Total - subtotal -> Total - cantidad * precioUnitario)
    SET @totalSinDetalle = (SELECT total FROM Ventas.Factura WHERE idFactura = @idFactura) -
                           (((SELECT cantidad FROM Ventas.DetalleFactura WHERE idFactura = @idFactura AND idDetalleFactura = @numDetalle))
                           *((SELECT precioUnitario FROM Ventas.DetalleFactura WHERE idFactura = @idFactura AND idDetalleFactura = @numDetalle))) 


    -- Recupera la cantidad en caso de que no se inserte nada para poder calcular el nuevo subtotal
    SET @cantidad = ISNULL(@cantidad,(SELECT cantidad FROM Ventas.DetalleFactura WHERE idFactura = @idFactura AND idDetalleFactura = @numDetalle))
	
	IF @precioUnitario IS NOT NULL
	BEGIN
		IF @idProducto IS NOT NULL AND @producto IS NOT NULL
			-- Si se actualiza el producto y no se especifica precio, se actualiza automaticamente
			SET @precioUnitario = (SELECT precioUnitario FROM Inventario.Producto WHERE idProducto = @idProducto)
	END
	ELSE
		-- Si es nulo se recupera el precio unitario original
		SET @precioUnitario = (SELECT precioUnitario FROM Ventas.DetalleFactura WHERE idFactura = @idFactura AND idDetalleFactura = @numDetalle)


    UPDATE Ventas.DetalleFactura
    SET idProducto     = ISNULL(@idProducto, idProducto),
        cantidad       = @cantidad,
        precioUnitario = @precioUnitario,
        subtotal       = @cantidad * @precioUnitario
    WHERE idDetalleFactura = @numDetalle AND idFactura = @idFactura

    -- Actualizamos el total de la factura
    UPDATE Ventas.Factura
    SET total = @totalSinDetalle + @cantidad * @precioUnitario
    WHERE idFactura = @idFactura;
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Ventas.EliminarDetalleFactura_sp
    @codigoFactura  VARCHAR(25),
    @numDetalle     INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @idFactura INT,
            @subtotal DECIMAL(10,2);

    IF @codigoFactura NOT LIKE ('[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]')
	BEGIN
		RAISERROR('El formato de codigo de factura es inválido.',16,1);
		RETURN;
	END

    SET @idFactura = (SELECT idFactura FROM Ventas.Factura WHERE codigoFactura = @codigoFactura AND activo = 1)
    IF @idFactura IS NULL
	BEGIN
        RAISERROR('La factura no existe o no está activa.', 16, 1);
		RETURN;
	END

    IF NOT EXISTS (SELECT 1 FROM Ventas.DetalleFactura WHERE idFactura = @idFactura AND idDetalleFactura = @numDetalle)
	BEGIN
        RAISERROR('No existe el detalle de venta de la factura indicada.', 16, 1);
		RETURN;
	END

    SET @subtotal = (SELECT subtotal FROM Ventas.DetalleFactura WHERE idFactura = @idFactura AND idDetalleFactura = @numDetalle)

	UPDATE Ventas.Factura
    SET total = total - @subtotal
    WHERE idFactura = @idFactura;

    DELETE FROM Ventas.DetalleFactura WHERE idFactura = @idFactura AND idDetalleFactura = @numDetalle;
END;
GO

----------------------------------------------------------------------------------------------
-- ABM Ventas.NotaCredito
CREATE PROCEDURE Ventas.InsertarNotaCredito_sp
    @codigoNota     VARCHAR(25),
    @codigoFactura  VARCHAR(25),
	@cliente        VARCHAR(25),
    @empleado       INT,
    @fecha		    DATETIME = NULL,
    @detalles	    NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @idFactura  INT,
            @idCliente  INT,
            @idEmpleado INT;

    IF @codigoNota NOT LIKE ('NC-2[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]')
	BEGIN
		RAISERROR('El formato de código de nota de crédito es inválido (NC-2YYY-000000).',16,1);
		RETURN;
	END

    IF EXISTS (SELECT 1 FROM Ventas.NotaCredito WHERE codigoNota = @codigoNota)
    BEGIN
		RAISERROR('La nota de crédito ya existe.',16,1);
		RETURN;
	END

    IF @codigoFactura NOT LIKE ('[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]')
	BEGIN
		RAISERROR('El formato de código de factura es inválido.',16,1);
		RETURN;
	END

    SET @idFactura = (SELECT idFactura FROM Ventas.Factura WHERE codigoFactura = @codigoFactura AND activo = 1)
    IF @idFactura IS NULL
	BEGIN
        RAISERROR('La factura no existe o no está activa.', 16, 1);
		RETURN;
	END

    IF @cliente NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
	BEGIN
		RAISERROR('El formato de cliente es inválido.',16,1)
		RETURN;
	END

    SET @idCliente = (SELECT idCliente FROM Ventas.Cliente WHERE dniHASH = HASHBYTES('SHA2_256', @cliente) AND activo = 1)
    IF @idCliente IS NULL
    BEGIN
	    RAISERROR('El cliente no existe o no se enecuentra activo.', 16, 1);
        RETURN;
    END
    
    IF @idCliente <> (SELECT idCliente FROM Ventas.Factura WHERE idFactura = @idFactura)
    BEGIN
	    RAISERROR('El cliente no concuerda con la factura.', 16, 1);
        RETURN;
    END

    IF @empleado <= 0
	BEGIN
		RAISERROR('El formato deL legajo del empleado es inválido.',16,1)
		RETURN;
	END
    
    SET @idEmpleado = (SELECT idEmpleado FROM Empresa.Empleado WHERE legajo = @empleado AND activo = 1)
    IF @idEmpleado IS NULL
    BEGIN
	    RAISERROR('El empleado no existe o no se enecuentra activo.', 16, 1);
        RETURN;
    END

    IF LEN(LTRIM(RTRIM(@detalles))) = 0 
    BEGIN
        RAISERROR('El detalle de la nota de crédito no puede estar vacio.', 16, 1);
        RETURN;
    END

    INSERT INTO Ventas.NotaCredito (
        codigoNota,
        idFactura,
		idCliente,
        idEmpleado,
        fecha,
        detalles
    )
    VALUES (
        @codigoNota,
        @idFactura,
		@idCliente,
        @idEmpleado,
        ISNULL(@fecha, GETDATE()),
        @detalles
    );
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Ventas.ActualizarNotaCredito_sp
    @codigoNota     VARCHAR(25),
	@cliente        VARCHAR(25) = NULL,
    @empleado       INT = NULL,
    @fecha		    DATETIME = NULL,
    @detalles	    NVARCHAR(200) = NULL,
    @nuevoCodigo    VARCHAR(25) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @idFactura  INT,
            @idCliente  INT,
            @idEmpleado INT;

    IF @cliente IS NULL AND @empleado IS NULL AND @fecha IS NULL AND @detalles IS NULL AND @nuevoCodigo IS NULL
    BEGIN
		RAISERROR('Debe indicar al menos un cambio.', 16, 1);
		RETURN;
	END

    IF @codigoNota NOT LIKE ('NC-2[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]')
	BEGIN
		RAISERROR('El formato de codigo de nota de crédito es inválido (NC-2YYY-000000).',16,1);
		RETURN;
	END

    IF NOT EXISTS (SELECT 1 FROM Ventas.NotaCredito WHERE codigoNota = @codigoNota AND activo = 1)
    BEGIN
		RAISERROR('La nota de crédito no existe o no se encuentra activa.',16,1);
		RETURN;
	END
    
    IF @cliente NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
	BEGIN
		RAISERROR('El formato del nuevo cliente es inválido.',16,1)
		RETURN;
	END

    SET @idCliente = (SELECT idCliente FROM Ventas.Cliente WHERE dniHASH = HASHBYTES('SHA2_256', @cliente) AND activo = 1)
    IF @idCliente IS NULL AND @cliente IS NOT NULL
    BEGIN
	    RAISERROR('El nuevo cliente no existe o no se enecuentra activo.', 16, 1);
        RETURN;
    END

    IF @cliente IS NOT NULL AND @idCliente <> (SELECT idCliente FROM Ventas.Factura WHERE idFactura = @idFactura)
    BEGIN
	    RAISERROR('El cliente no concuerda con la factura.', 16, 1);
        RETURN;
    END

    IF LEN(LTRIM(RTRIM(@detalles))) = 0 
    BEGIN
        RAISERROR('El nuevo detalle de la nota de crédito no puede estar vacio.', 16, 1);
        RETURN;
    END

    IF @nuevoCodigo IS NOT NULL AND @nuevoCodigo <> @codigoNota
    BEGIN
        IF @codigoNota NOT LIKE ('NC-2[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]')
	    BEGIN
		    RAISERROR('El formato del nuevo codigo de nota de crédito es inválido (NC-2YYY-000000).',16,1);
		    RETURN;
	    END

        IF EXISTS (SELECT 1 FROM Ventas.NotaCredito WHERE codigoNota = @nuevoCodigo)
        BEGIN
		    RAISERROR('El nuevo código de nota de credito ya está en uso.',16,1);
		    RETURN;
	    END
    END

    UPDATE Ventas.NotaCredito
    SET codigoNota	      = ISNULL(@nuevoCodigo, codigoNota),
		idCliente		  = ISNULL(@idCliente, idCliente),
        fecha			  = ISNULL(@fecha, fecha),
        detalles          = ISNULL(@detalles, detalles)
    WHERE codigoNota = @codigoNota;
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Ventas.EliminarNotaCredito_sp
    @codigoNota  VARCHAR(25)
AS
BEGIN
    SET NOCOUNT ON;

    IF @codigoNota NOT LIKE ('NC-2[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]')
	BEGIN
	    RAISERROR('El formato del nuevo codigo de nota de crédito es inválido (NC-2YYY-000000).',16,1);
	    RETURN;
	END

    IF NOT EXISTS (SELECT 1 FROM Ventas.NotaCredito WHERE codigoNota = @codigoNota AND activo = 1)
	BEGIN
        RAISERROR('No existe la nota de crédito indicada o no se encuentra activa.', 16, 1);
    	RETURN;
	END

    UPDATE Ventas.NotaCredito
    SET activo = 0
    WHERE codigoNota = @codigoNota;
END;
GO

----------------------------------------------------------------------------------------------
CREATE PROCEDURE Ventas.ReactivarNotaCredito_sp
    @codigoNota  VARCHAR(25)
AS
BEGIN
    SET NOCOUNT ON;

    IF @codigoNota NOT LIKE ('NC-2[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]')
	BEGIN
	    RAISERROR('El formato del nuevo codigo de nota de crédito es inválido (NC-2YYY-000000).',16,1);
	    RETURN;
	END

    IF NOT EXISTS (SELECT 1 FROM Ventas.NotaCredito WHERE codigoNota = @codigoNota AND activo = 0)
	BEGIN
        RAISERROR('No existe la nota de crédito indicada o ya se encuentra activa.', 16, 1);
    	RETURN;
	END

    UPDATE Ventas.NotaCredito
    SET activo = 1
    WHERE codigoNota = @codigoNota;
END;
GO

----------------------------------------------------------------------------------------------
-- ABN Ventas.DetalleNota
CREATE PROCEDURE Ventas.InsertarDetalleNota_sp
    @codigoNota     VARCHAR(25),
    @producto       NVARCHAR(100),
    @cantidad       INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @idNota            INT, 
            @idFactura         INT,
            @idProducto        INT,
            @idDetalleFactura  INT,
            @cantidadTotal     INT,
            @cantidadDevuelta  INT,
            @idDetalleNota     INT,
            @precioUnitario    DECIMAL(10,2);
    
    IF @codigoNota NOT LIKE ('NC-2[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]')
	BEGIN
	    RAISERROR('El formato del codigo de nota de crédito es inválido (NC-2YYY-000000).',16,1);
	    RETURN;
	END

    SET @idNota = (SELECT idNota FROM Ventas.NotaCredito WHERE codigoNota = @codigoNota AND activo = 1)
    IF @idNota IS NULL
	BEGIN
        RAISERROR('No existe la nota de crédito indicada o no se encuentra activa.', 16, 1);
    	RETURN;
	END

    SET @idFactura = (SELECT idFactura FROM Ventas.NotaCredito WHERE idNota = @idNota)

    SET @idProducto = (SELECT idProducto FROM Inventario.Producto WHERE nombreProducto = @producto)
    IF @idProducto IS NULL
	BEGIN
        RAISERROR('El producto no existe.', 16, 1);
    	RETURN;
	END

    IF EXISTS (SELECT 1 FROM Ventas.DetalleNota WHERE idNota = @idNota AND idProducto = @idProducto)
    BEGIN
        RAISERROR('Ya existe un detalle de nota con el producto ingresado.', 16, 1);
    	RETURN;
    END

    SET @idDetalleFactura = (SELECT idDetalleFactura FROM Ventas.DetalleFactura WHERE idFactura = @idFactura AND idProducto = @idProducto)
    IF @idDetalleFactura IS NULL
    BEGIN
        RAISERROR('El producto no está en la factura.', 16, 1);
    	RETURN;
	END

    -- Recuperamos precioUnitario y cantidad del detalle de la factura
    SET @precioUnitario = (SELECT precioUnitario FROM Ventas.DetalleFactura WHERE idFactura = @idFactura AND idDetalleFactura = @idDetalleFactura)
    SET @cantidadTotal = (SELECT cantidad FROM Ventas.DetalleFactura WHERE idFactura = @idFactura AND idDetalleFactura = @idDetalleFactura)

    SET @cantidadDevuelta = ( SELECT SUM(cantidad) FROM Ventas.DetalleNota D JOIN Ventas.NotaCredito N ON D.idNota = N.idNota
							  WHERE N.idFactura = @idFactura AND idProducto = @idProducto)

    IF @cantidad > @cantidadTotal
    BEGIN
        RAISERROR('La cantidad ingresada fue mayor que la facturada.', 16, 1);
    	RETURN;
	END

    IF @cantidadDevuelta + @cantidad > @cantidadTotal
    BEGIN
        RAISERROR('Se facturaron menos productos de la cantidad ingresada teniendo en cuenta otras notas de crédito.', 16, 1);
    	RETURN;
	END

	IF @cantidad <= 0
	BEGIN
        RAISERROR('La cantidad debe ser mayor a 0.', 16, 1);
		RETURN;
	END
	
	-- Crear el idDetalle para que sea consecutivo al ultimo numero correspondiente a la factura accedida 
    SET @idDetalleNota = ISNULL((SELECT MAX(idDetalleNota) FROM Ventas.DetalleNota WHERE idNota = @idNota), 0) + 1;

    INSERT INTO Ventas.DetalleNota(
        idNota,
        idDetalleNota,
        idProducto,
        cantidad,
        precioUnitario,
        subtotal
    )
    VALUES (
        @idNota,
        @idDetalleNota,
        @idProducto,
        @cantidad,
        @precioUnitario,
        (@cantidad * @precioUnitario)  -- Calculamos subtotal
    );

	-- Actualizar monto total en NotaCredito
    UPDATE Ventas.NotaCredito
    SET monto = monto + (@cantidad * @precioUnitario)
    WHERE idNota = @idNota;
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Ventas.ActualizarDetalleNota_sp
    @codigoNota     VARCHAR(25),
    @numDetalle		INT,
    @producto       NVARCHAR(100) = NULL,
    @cantidad       INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @idDetalleNota		INT,
            @idNota				INT,
            @idFactura			INT,
            @idProducto			INT,
			@idDetalleFactura	INT,
            @montoSinDetalle	DECIMAL(10,2),
            @precioUnitario		DECIMAL(10,2) = NULL,
			@cantidadTotal		INT,
            @cantidadDevuelta	INT;

    IF @producto IS NULL AND @cantidad IS NULL 
    BEGIN
        RAISERROR('Debe indicar al menos un cambio.', 16, 1);
		RETURN;
	END

    IF @codigoNota NOT LIKE ('NC-2[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]')
	BEGIN
	    RAISERROR('El formato del nuevo codigo de nota de crédito es inválido (NC-2YYY-000000).',16,1);
	    RETURN;
	END

    SET @idNota = (SELECT idNota FROM Ventas.NotaCredito WHERE codigoNota = @codigoNota AND activo = 1)
    IF @idNota IS NULL
	BEGIN
        RAISERROR('No existe la nota de crédito indicada o no se encuentra activa.', 16, 1);
    	RETURN;
	END

    SET @idDetalleNota = (SELECT idDetalleNota FROM Ventas.DetalleNota WHERE idNota = @idNota AND idDetalleNota = @numDetalle)
    IF @idDetalleNota IS NULL
	BEGIN
        RAISERROR('No existe el detalle de la nota de crédito indicada.', 16, 1);
    	RETURN;
	END

    SET @idFactura = (SELECT idFactura FROM Ventas.NotaCredito WHERE idNota =  @idNota)

    IF @producto IS NULL
        SET @idProducto = (SELECT idProducto FROM Ventas.DetalleNota WHERE idNota = @idNota AND idDetalleNota = @numDetalle)
    ELSE
        SET @idProducto = (SELECT idProducto FROM Inventario.Producto WHERE nombreProducto = @producto)
    
    IF @idProducto IS NULL AND @producto IS NOT NULL 
	BEGIN
        RAISERROR('El producto no existe.', 16, 1);
    	RETURN;
	END

    IF EXISTS (SELECT 1 FROM Ventas.DetalleNota WHERE idNota = @idNota AND idProducto = @idProducto AND idDetalleNota <> @numDetalle)
    BEGIN
        RAISERROR('Ya existe un detalle de nota con el producto ingresado.', 16, 1);
    	RETURN;
    END

    SET @idDetalleFactura = (SELECT idDetalleFactura FROM Ventas.DetalleFactura WHERE idFactura = @idFactura AND idProducto = @idProducto)
    IF @idDetalleFactura IS NULL
    BEGIN
        RAISERROR('El producto no está en la factura.', 16, 1);
    	RETURN;
	END

	IF @cantidad <= 0
	BEGIN
        RAISERROR('La cantidad debe ser mayor a 0.', 16, 1);
		RETURN;
	END

    -- Cantidad total facturada
	SET @cantidadTotal = (SELECT cantidad FROM Ventas.DetalleFactura WHERE idFactura = @idFactura AND idDetalleFactura = @idDetalleFactura)

	-- Precio unitario previo a modificar
    SET @precioUnitario = (SELECT precioUnitario FROM Ventas.DetalleNota WHERE idNota = @idNota AND idDetalleNota = @numDetalle)
    
	-- Monto total de la nota de crédito sin contar el detalle actual actualizado
    SET @montoSinDetalle = (SELECT monto FROM Ventas.NotaCredito WHERE idNota = @idNota) - @precioUnitario * (SELECT cantidad FROM Ventas.DetalleNota WHERE idNota = @idNota AND idDetalleNota = @numDetalle)

    -- Actualizamos precioUnitario si se actualiza el producto
    IF @producto IS NOT NULL
        SET @precioUnitario = (SELECT precioUnitario FROM Ventas.DetalleFactura WHERE idFactura = @idFactura AND idDetalleFactura = @idDetalleFactura)
    
	-- Cantidad devuelta acumulada del producto en todas las notas de crédito de la factura
    SET @cantidadDevuelta = ( SELECT SUM(cantidad) FROM Ventas.DetalleNota D JOIN Ventas.NotaCredito N ON D.idNota = N.idNota
							  WHERE N.idFactura = @idFactura AND idProducto = @idProducto)

    IF @cantidad > @cantidadTotal
    BEGIN
        RAISERROR('La cantidad ingresada fue mayor que la facturada.', 16, 1);
    	RETURN;
	END

    IF @cantidadDevuelta + @cantidad > @cantidadTotal
    BEGIN
        RAISERROR('Se facturaron menos productos de la cantidad ingresada teniendo en cuenta otras notas de crédito.', 16, 1);
    	RETURN;
	END

    -- Recupera la cantidad en caso de que no se inserte nada para poder calcular el nuevo subtotal
    SET @cantidad = ISNULL(@cantidad,(SELECT cantidad FROM Ventas.DetalleNota WHERE idNota = @idNota AND idDetalleNota = @numDetalle))
	
    UPDATE Ventas.DetalleNota
    SET idProducto     = ISNULL(@idProducto, idProducto),
        cantidad       = ISNULL(@cantidad, cantidad),
        precioUnitario = ISNULL(@precioUnitario, precioUnitario),
        subtotal       = @cantidad * @precioUnitario
    WHERE idNota = @idNota AND idDetalleNota = @numDetalle  

    UPDATE Ventas.NotaCredito
    SET monto = @montoSinDetalle + (@cantidad * @precioUnitario)
    WHERE idNota = @idNota;
END;
GO
----------------------------------------------------------------------------------------------
CREATE  PROCEDURE Ventas.EliminarDetalleNota_sp
    @codigoNota     VARCHAR(25),
    @numeroDetalle  INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @idNota INT,
            @subtotal DECIMAL(10,2);

    IF @codigoNota NOT LIKE ('NC-2[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]')
	BEGIN
	    RAISERROR('El formato del codigo de nota de crédito es inválido (NC-2YYY-000000).',16,1);
	    RETURN;
	END

    SET @idNota = (SELECT idNota FROM Ventas.NotaCredito WHERE codigoNota = @codigoNota AND activo = 1)
    IF @idNota IS NULL
	BEGIN
        RAISERROR('La nota de crédito no existe o no está activa.', 16, 1);
		RETURN;
	END

    IF NOT EXISTS (SELECT 1 FROM Ventas.DetalleNota WHERE idDetalleNota = @numeroDetalle AND idNota = @idNota)
	BEGIN
        RAISERROR('No existe el detalle indicado de la nota de crédito.', 16, 1);
		RETURN;
	END

    SET @subtotal = (SELECT subtotal FROM Ventas.DetalleNota WHERE idNota = @idNota AND idDetalleNota = @numeroDetalle)

	UPDATE Ventas.NotaCredito
    SET monto = monto - @subtotal
    WHERE idNota = @idNota;

    DELETE FROM Ventas.DetalleNota WHERE idNota = @idNota AND idDetalleNota = @numeroDetalle;
END;
GO




----------------------------------------------------------------------------------------------
-- Vacia todas las tablas y resetea los autoincrementales identity
CREATE  PROCEDURE Utilidades.ResetearTablas_sp
AS
BEGIN
    SET NOCOUNT ON;

	-- Vaciar tablas
    DELETE FROM Ventas.DetalleFactura;
    DELETE FROM Ventas.Factura;
    DELETE FROM Ventas.DetalleNota;
    DELETE FROM Ventas.NotaCredito;
    DELETE FROM Ventas.MedioPago;
    DELETE FROM Ventas.Cliente;
    DELETE FROM Empresa.Empleado;
    DELETE FROM Empresa.Cargo;
    DELETE FROM Empresa.Turno;
    DELETE FROM Empresa.Sucursal;
    DELETE FROM Inventario.Producto;
    DELETE FROM Inventario.LineaProducto;
    
    -- Resetear los contadores de IDENTITY
    DBCC CHECKIDENT ('Ventas.Factura', RESEED, 0);
    DBCC CHECKIDENT ('Ventas.Cliente', RESEED, 0);
	DBCC CHECKIDENT ('Ventas.NotaCredito', RESEED, 0);
    DBCC CHECKIDENT ('Ventas.MedioPago', RESEED, 0);
    DBCC CHECKIDENT ('Empresa.Sucursal', RESEED, 0);
    DBCC CHECKIDENT ('Empresa.Empleado', RESEED, 0);
    DBCC CHECKIDENT ('Empresa.Cargo', RESEED, 0);
    DBCC CHECKIDENT ('Empresa.Turno', RESEED, 0);
    DBCC CHECKIDENT ('Inventario.Producto', RESEED, 0);
    DBCC CHECKIDENT ('Inventario.LineaProducto', RESEED, 0);
END;
GO
