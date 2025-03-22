/*
Aurora SA
Script de creacion de procedures ABM (Alta - Baja - Modificacion)
GRodriguezAR
*/

USE [AuroraSA_DB]
GO

------------------------------- FUNCIONES DE UTILIDAD -------------------------------------------
-- Validar el formato del CUIL (XX-XXXXXXXX-X)
CREATE OR ALTER FUNCTION Utilidades.ValidarCuil(@cuil VARCHAR(13))
RETURNS BIT
AS
BEGIN
	IF	@cuil LIKE '2[0347]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9]' OR
		@cuil LIKE '3[034]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9]'
        RETURN 1;
    RETURN 0;
END;
GO

-- Validar formato de email personal
CREATE OR ALTER FUNCTION Utilidades.ValidarEmailPersonal(@email VARCHAR(255))
RETURNS BIT
AS
BEGIN
    IF @email LIKE '_%@_%._%' 
		RETURN 1;
    RETURN 0;
END;
GO

-- Validar formato de email empresa
CREATE OR ALTER FUNCTION Utilidades.ValidarEmailEmpresa(@email VARCHAR(255))
RETURNS BIT
AS
BEGIN
    IF LOWER(@email) LIKE '_%@aurorsa.com.ar' 
		RETURN 1;
    RETURN 0;
END;
GO

-- Validar género (Solo M o F)
CREATE OR ALTER FUNCTION Utilidades.ValidarGenero(@genero CHAR(1))
RETURNS BIT
AS
BEGIN
    IF @genero IN ('M', 'F')
        RETURN 1;
    RETURN 0;
END;
GO


----------------------------------------------------------------------------------------------
-- ABM Empresa.Sucursal
CREATE OR ALTER PROCEDURE Empresa.InsertarSucursal_sp
	@codigoSucursal	 CHAR(3),
    @direccion       NVARCHAR(100),
    @ciudad          VARCHAR(50),
    @telefono        CHAR(10),
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
CREATE OR ALTER PROCEDURE Empresa.ActualizarSucursal_sp
    @codigoSucursal  CHAR(3),
    @direccion       NVARCHAR(100) = NULL,
    @ciudad          VARCHAR(50) = NULL,
    @telefono        CHAR(10) = NULL,
    @horario         VARCHAR(55) = NULL,
	@nuevoCodigo	 CHAR(3) = NULL,
    @activo          BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @direccion IS NULL AND @ciudad IS NULL AND @telefono IS NULL AND @horario IS NULL AND @nuevoCodigo IS NULL AND @activo IS NULL
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
    IF NOT EXISTS (SELECT 1 FROM Empresa.Sucursal WHERE codigoSucursal = @codigoSucursal)
    BEGIN    
		RAISERROR('No existe la sucursal indicada.', 16, 1);
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

    IF @activo NOT IN (0,1)
    BEGIN
         RAISERROR('Activo solo puede tener los valores 0 y 1.', 16, 1);
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
		codigoSucursal	= ISNULL(@nuevoCodigo, codigoSucursal),
        activo          = ISNULL(@activo, activo)
	WHERE codigoSucursal = @codigoSucursal;
	
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Empresa.EliminarSucursal_sp
    @codigoSucursal CHAR(3)
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
-- ABM Empresa.Cargo
CREATE OR ALTER PROCEDURE Empresa.InsertarCargo_sp
	@nombre VARCHAR(20),
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
CREATE OR ALTER PROCEDURE Empresa.ActualizarCargo_sp
	@nombre      VARCHAR(20),
    @descripcion NVARCHAR(100) = NULL,
	@nuevoNombre VARCHAR(20) = NULL,
    @activo      BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @descripcion IS NULL AND @nuevoNombre IS NULL AND @activo IS NULL
    BEGIN
        RAISERROR('Debe indicar al menos un cambio.', 16, 1);
		RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Empresa.Cargo WHERE nombre = @nombre)
	BEGIN
        RAISERROR('El cargo no existe.', 16, 1);
		RETURN;
	END

    IF LEN(LTRIM(RTRIM(@descripcion))) = 0
    BEGIN
         RAISERROR('La descripción del cargo no puede estar vacía.', 16, 1);
         RETURN;
    END

    IF @activo NOT IN (0,1)
    BEGIN
         RAISERROR('Activo solo puede tener los valores 0 y 1.', 16, 1);
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
		nombre      = ISNULL(@nuevoNombre,nombre),
        activo      = ISNULL(@activo, activo)
    WHERE nombre = @nombre;
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Empresa.EliminarCargo_sp
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
-- ABM Empresa.Turno
CREATE OR ALTER PROCEDURE Empresa.InsertarTurno_sp
	@acronimo CHAR(2),
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
CREATE OR ALTER PROCEDURE Empresa.ActualizarTurno_sp
	@acronimo       CHAR(2),
    @descripcion    VARCHAR(25) = NULL,
	@nuevoAcronimo  CHAR(2) = NULL,
    @activo         BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @descripcion IS NULL AND @nuevoAcronimo IS NULL AND @activo IS NULL
    BEGIN
        RAISERROR('Debe indicar al menos un cambio.', 16, 1);
		RETURN;
    END

    IF @acronimo NOT LIKE '[A-Z][A-Z]'
	BEGIN
        RAISERROR('El formato de turno es inválido.', 16, 1);
		RETURN;
	END

    IF NOT EXISTS (SELECT 1 FROM Empresa.Turno WHERE acronimo = @acronimo)
	BEGIN
        RAISERROR('El turno no existe.', 16, 1);
		RETURN;
	END

	IF LEN(LTRIM(RTRIM(@descripcion))) = 0
    BEGIN
         RAISERROR('La nueva descripción del turno no puede estar vacía.', 16, 1);
         RETURN;
    END

    IF @activo NOT IN (0,1)
    BEGIN
         RAISERROR('Activo solo puede tener los valores 0 y 1.', 16, 1);
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
		acronimo    = ISNULL(@nuevoAcronimo, acronimo),
        activo      = ISNULL(@activo, activo)
    WHERE acronimo = @acronimo;
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Empresa.EliminarTurno_sp
	@acronimo CHAR(2) 
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
-- ABM Empresa.Empleado
CREATE OR ALTER PROCEDURE Empresa.InsertarEmpleado_sp
    @legajo         INT,
    @nombre			VARCHAR(30),
    @apellido		VARCHAR(30),
    @genero			CHAR(1),
    @cuil			CHAR(13),
    @telefono		CHAR(10),
    @domicilio		NVARCHAR(100),
    @fechaAlta		DATE = NULL,
    @mailPersonal	VARCHAR(55),
    @mailEmpresa	VARCHAR(55),
    @cargo          VARCHAR(20),
    @sucursal       CHAR(3),
    @turno          CHAR(2)
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

	IF Utilidades.ValidarGenero(@genero) = 0
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
	IF Utilidades.ValidarEmailPersonal(@mailPersonal) = 0
	BEGIN
		RAISERROR('El formato de mail personal es inválido.', 16, 1);
		RETURN;
	END

	IF Utilidades.ValidarEmailEmpresa(@mailEmpresa) = 0
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
		@genero,
        EncryptByKey(Key_GUID('LlaveSimetrica'), @cuil),
        HASHBYTES('SHA2_512', @cuil),
		EncryptByKey(Key_GUID('LlaveSimetrica'), @telefono),
        EncryptByKey(Key_GUID('LlaveSimetrica'), @domicilio),
		ISNULL(@fechaAlta,GETDATE()),
        EncryptByKey(Key_GUID('LlaveSimetrica'), @mailPersonal),
		@mailEmpresa,
		@idCargo,
        @idSucursal,
		@idTurno
    );
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Empresa.ActualizarEmpleado_sp
    @legajo         INT,
    @nombre			VARCHAR(30) = NULL,
    @apellido		VARCHAR(30) = NULL,
    @genero			CHAR(1) = NULL,
    @cuil			CHAR(13) = NULL,
    @telefono		CHAR(10) = NULL,
    @domicilio		NVARCHAR(100) = NULL,
    @fechaAlta		DATE = NULL,
    @mailPersonal	VARCHAR(55) = NULL,
    @mailEmpresa	VARCHAR(55) = NULL,
    @cargo          VARCHAR(20) = NULL,
    @sucursal       CHAR(3) = NULL,
    @turno          CHAR(2) = NULL,
    @nuevoLegajo    CHAR(13) = NULL,
    @activo         BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @idCargo    INT,
            @idSucursal INT,
            @idTurno    INT;

    IF @nombre IS NULL AND @apellido IS NULL AND @genero IS NULL AND @cuil IS NULL AND @telefono IS NULL AND @domicilio IS NULL AND @fechaAlta IS NULL
       AND @mailPersonal IS NULL AND @mailEmpresa IS NULL AND @cargo IS NULL AND @sucursal IS NULL AND @turno IS NULL AND @nuevoLegajo IS NULL AND @activo IS NULL
    BEGIN
        RAISERROR('Debe indicar al menos un cambio.', 16, 1);
		RETURN;
    END

    IF @legajo <= 0
    BEGIN
		RAISERROR('El formato de legajo es inválido.',16,1)
		RETURN;
	END

    IF NOT EXISTS (SELECT 1 FROM Empresa.Empleado WHERE legajo = @legajo)
    BEGIN
		RAISERROR('El empleado no existe', 16, 1);
	END

    IF Utilidades.ValidarCuil(@cuil) = 0
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

	IF Utilidades.ValidarGenero(@genero) = 0
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

	IF Utilidades.ValidarEmailPersonal(@mailPersonal) = 0
	BEGIN
		RAISERROR('El formato del nuevo mail personal es inválido.', 16, 1);
		RETURN;
	END

	IF Utilidades.ValidarEmailEmpresa(@mailEmpresa) = 0
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

    IF @activo NOT IN (0,1)
    BEGIN
         RAISERROR('Activo solo puede tener los valores 0 y 1.', 16, 1);
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
		genero	     = ISNULL(@genero, genero),
		cuil	     = ISNULL(EncryptByKey(Key_GUID('LlaveSimetrica'), @cuil), cuil),
        cuilHASH     = ISNULL(HASHBYTES('SHA2_512', @cuil), cuilHASH),
        telefono     = ISNULL(EncryptByKey(Key_GUID('LlaveSimetrica'), @telefono), telefono),
		domicilio    = ISNULL(EncryptByKey(Key_GUID('LlaveSimetrica'), @domicilio), domicilio),
		fechaAlta    = ISNULL(@fechaAlta, fechaAlta),
		mailPersonal = ISNULL(EncryptByKey(Key_GUID('LlaveSimetrica'), @mailPersonal), mailPersonal),
		mailEmpresa  = ISNULL(@mailEmpresa, mailEmpresa),
        idCargo      = ISNULL(@idCargo, idCargo),
		idSucursal   = ISNULL(@idSucursal, idSucursal),
		idTurno	     = ISNULL(@idTurno, idTurno),
        activo       = ISNULL(@activo, activo)
    WHERE legajo = @legajo;
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Empresa.EliminarEmpleado_sp
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
-- ABM Inventario.LineaProducto
CREATE OR ALTER PROCEDURE Inventario.InsertarLineaProducto_sp
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
CREATE OR ALTER PROCEDURE Inventario.ActualizarLineaProducto_sp
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

	IF NOT EXISTS (SELECT 1 FROM Inventario.LineaProducto WHERE descripcion = @descripcion)
	BEGIN
		RAISERROR('La linea de producto no existe.',16,1);
		RETURN;
	END

    IF @activo NOT IN (0,1)
    BEGIN
         RAISERROR('Activo solo puede tener los valores 0 y 1.', 16, 1);
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
	SET descripcion = ISNULL(@nuevaDescripcion, descripcion),
        activo      = ISNULL(@activo, activo)
	WHERE descripcion = @descripcion;
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Inventario.EliminarLineaProducto_sp
	@descripcion VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;

	IF NOT EXISTS (SELECT 1 FROM Inventario.LineaProducto WHERE descripcion = @descripcion AND activo = 1)
	BEGIN
		RAISERROR('La linea de producto no existe o no esta activa.',16,1);
		RETURN;
	END

	UPDATE Inventario.LineaProducto
	SET activo = 0
	WHERE descripcion = @descripcion;
END;
GO


----------------------------------------------------------------------------------------------
-- ABM Inventario.Producto	
CREATE OR ALTER PROCEDURE Inventario.InsertarProducto_sp
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
CREATE OR ALTER PROCEDURE Inventario.ActualizarProducto_sp
    @nombreProducto   NVARCHAR(100),
    @lineaProducto    VARCHAR(30) = NULL,
    @precioUnitario   DECIMAL(10,2) = NULL,
    @nuevoNombreProd  NVARCHAR(100) = NULL,
    @activo           BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @idLinea INT

    IF @lineaProducto IS NULL AND @precioUnitario IS NULL AND @nuevoNombreProd IS NULL AND @activo IS NULL
    BEGIN
        RAISERROR('Debe indicar al menos un cambio.', 16, 1);
		RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Inventario.Producto WHERE nombreProducto = @nombreProducto)
    BEGIN
		RAISERROR('El producto no existe.', 16, 1);
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

    IF @activo NOT IN (0,1)
    BEGIN
         RAISERROR('Activo solo puede tener los valores 0 y 1.', 16, 1);
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
        precioUnitario  = ISNULL(@precioUnitario, precioUnitario),
        activo          = ISNULL(@activo, activo)
    WHERE nombreProducto = @nombreProducto;
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Inventario.EliminarProducto_sp
    @nombreProducto   NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Inventario.Producto WHERE nombreProducto = @nombreProducto AND activo = 1)
	BEGIN
        RAISERROR('El producto no existe o no está activo.', 16, 1);
		RETURN;
	END
      
    UPDATE Inventario.Producto
    SET activo = 0
    WHERE nombreProducto = @nombreProducto;
END;
GO
----------------------------------------------------------------------------------------------
-- ABM Ventas.Cliente
CREATE OR ALTER PROCEDURE Ventas.InsertarCliente_sp
    @dni                CHAR(8),
    @nombre				VARCHAR(30),
    @apellido			VARCHAR(30),
    @genero				CHAR(1),
    @tipoCliente		VARCHAR(10),
    @puntos             INT,
    @fechaAlta          DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @dni NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
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

	IF Utilidades.ValidarGenero(@genero) = 0
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
        @genero,
		@tipoCliente,
		@puntos,
        ISNULL(@fechaAlta,GETDATE())
    );
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Ventas.ActualizarCliente_sp
    @dni                CHAR(8),
    @nombre				VARCHAR(30) = NULL,
    @apellido			VARCHAR(30) = NULL,
    @genero				CHAR(1) = NULL,
    @tipoCliente		VARCHAR(10) = NULL,
    @puntos             INT = NULL,
    @activo             BIT = NULL,
    @fechaAlta          DATETIME = NULL,
    @nuevoDni           CHAR(8) = NULL
   
AS
BEGIN
    SET NOCOUNT ON;

    IF @nombre IS NULL AND @apellido IS NULL AND @genero IS NULL AND @tipoCliente IS NULL AND @puntos IS NULL AND @activo IS NULL AND @fechaAlta IS NULL AND @nuevoDni IS NULL
    BEGIN
        RAISERROR('Debe indicar al menos un cambio.', 16, 1);
		RETURN;
    END

    IF @dni NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
    BEGIN
		RAISERROR('El formato del dni es inválido.',16,1)
		RETURN;
	END

    IF NOT EXISTS (SELECT 1 FROM Ventas.Cliente WHERE dniHASH = HASHBYTES('SHA2_256', @dni))
	BEGIN
        RAISERROR('El cliente no existe.', 16, 1);
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

	IF Utilidades.ValidarGenero(@genero) = 0
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

    
    IF @activo NOT IN (0,1)
    BEGIN
         RAISERROR('Activo solo puede tener los valores 0 y 1.', 16, 1);
         RETURN;
    END

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
        fechaAlta   = ISNULL(@fechaAlta, fechaAlta),
        activo      = ISNULL(@activo, activo)
    WHERE dniHASH = HASHBYTES('SHA2_256', @dni);
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Ventas.EliminarCliente_sp
    @dni CHAR(8)
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
        RAISERROR('El cliente no existe o no está activo.', 16, 1);
		RETURN;
	END

    -- Borrado lógico
    UPDATE Ventas.Cliente
    SET activo = 0
    WHERE dniHASH = HASHBYTES('SHA2_256', @dni);
END;
GO

----------------------------------------------------------------------------------------------
-- ABM Ventas.MedioPago
CREATE OR ALTER PROCEDURE Ventas.InsertarMedioPago_sp
    @nombre      VARCHAR(10),
    @descripcion VARCHAR(20)
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

    IF LEN(LTRIM(RTRIM(@descripcion))) = 0
    BEGIN
         RAISERROR('La descripcion del medio de pago no puede estar vacía.', 16, 1);
         RETURN;
    END

    INSERT INTO Ventas.MedioPago (nombre, descripcion)
    VALUES (@nombre, @descripcion);
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Ventas.ActualizarMedioPago_sp
    @nombre      VARCHAR(10),
    @descripcion VARCHAR(20) = NULL,
    @nuevoNombre VARCHAR(10) = NULL,
    @activo      BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @descripcion IS NULL AND @nuevoNombre IS NULL AND @activo IS NULL
    BEGIN
        RAISERROR('Debe indicar al menos un cambio.', 16, 1);
		RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Ventas.MedioPago WHERE nombre = @nombre)
	BEGIN
        RAISERROR('El medio de pago no existe.', 16, 1);
		RETURN;
	END

    IF LEN(LTRIM(RTRIM(@descripcion))) = 0
    BEGIN
         RAISERROR('La nueva descripcion del medio de pago no puede estar vacía.', 16, 1);
         RETURN;
    END

    IF @activo NOT IN (0,1)
    BEGIN
         RAISERROR('Activo solo puede tener los valores 0 y 1.', 16, 1);
         RETURN;
    END

    IF @nuevoNombre IS NOT NULL AND @nuevoNombre <> @nombre
    BEGIN
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
    END

    UPDATE Ventas.MedioPago
    SET nombre      = ISNULL(@nuevoNombre, nombre),
        descripcion = ISNULL(@descripcion, descripcion),
        activo      = ISNULL(@activo, activo)
    WHERE nombre = @nombre;
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Ventas.EliminarMedioPago_sp
	@nombre VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

	IF NOT EXISTS (SELECT 1 FROM Ventas.MedioPago WHERE nombre = @nombre AND activo = 1)
	BEGIN
		RAISERROR('El medio de pago no existe o no esta activo.',16,1);
		RETURN;
	END

	UPDATE Ventas.MedioPago
	SET activo = 0
	WHERE nombre = @nombre;
END;
GO

----------------------------------------------------------------------------------------------
-- ABM Ventas.Factura
CREATE OR ALTER PROCEDURE Ventas.InsertarFactura_sp
    @codigoFactura		CHAR(11),
	@tipoFactura		CHAR(1),
    @fecha				DATETIME = NULL,
    @medioPago			VARCHAR(20),
    @detallesPago       VARCHAR(100) = NULL,
	@cliente		    CHAR(8),
    @empleado			INT,
    @sucursal			CHAR(3)
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
CREATE OR ALTER PROCEDURE Ventas.ActualizarFactura_sp
    @codigoFactura		CHAR(11),
	@tipoFactura		CHAR(1) = NULL,
    @fecha				DATETIME = NULL,
    @medioPago			VARCHAR(20) = NULL,
    @detallesPago       VARCHAR(100) = NULL,
	@cliente		    CHAR(8) = NULL,
    @empleado			INT = NULL,
    @sucursal			CHAR(3) = NULL,
    @activo             BIT = NULL,
    @nuevoCodigo        CHAR(11) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @idMedio    INT,
            @idCliente  INT,
            @idSucursal INT,
            @idEmpleado INT;

    IF @tipoFactura IS NULL AND @fecha IS NULL AND @medioPago IS NULL AND @detallesPago IS NULL AND @cliente IS NULL AND @empleado IS NULL AND 
    @sucursal IS NULL AND @activo IS NULL AND @nuevoCodigo IS NULL  
    BEGIN
		RAISERROR('Debe indicar al menos un cambio.', 16, 1);
		RETURN;
	END

    IF @codigoFactura NOT LIKE ('[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]')
	BEGIN
		RAISERROR('El formato de codigo de factura es inválido.',16,1);
		RETURN;
	END

    IF NOT EXISTS (SELECT 1 FROM Ventas.Factura WHERE codigoFactura = @codigoFactura)
    BEGIN
		RAISERROR('La factura no existe.',16,1);
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

    IF @activo NOT IN (0,1)
    BEGIN
         RAISERROR('Activo solo puede tener los valores 0 y 1.', 16, 1);
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
        idSucursal		  = ISNULL(@idSucursal, idSucursal),
        @activo           = ISNULL(@activo, activo)
    WHERE codigoFactura = @codigoFactura;
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Ventas.EliminarFactura_sp
    @codigoFactura CHAR(11)
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
-- ABM Ventas.DetalleFactura
CREATE OR ALTER PROCEDURE Ventas.InsertarDetalleFactura_sp
    @codigoFactura  CHAR(11),
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
CREATE OR ALTER PROCEDURE Ventas.ActualizarDetalleFactura_sp
    @codigoFactura  CHAR(11),
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
CREATE OR ALTER PROCEDURE Ventas.EliminarDetalleFactura_sp
    @codigoFactura  CHAR(11),
    @numDetalle  INT
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
CREATE OR ALTER PROCEDURE Ventas.InsertarNotaCredito_sp
    @codigoNota     CHAR(14),
    @codigoFactura  CHAR(11),
	@cliente        CHAR(8),
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
CREATE OR ALTER PROCEDURE Ventas.ActualizarNotaCredito_sp
    @codigoNota     CHAR(14),
	@cliente        CHAR(8) = NULL,
    @empleado       INT = NULL,
    @fecha		    DATETIME = NULL,
    @detalles	    NVARCHAR(200) = NULL,
    @activo         BIT = NULL,
    @nuevoCodigo    CHAR(14) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @idFactura  INT,
            @idCliente  INT,
            @idEmpleado INT;

    IF @cliente IS NULL AND @empleado IS NULL AND @fecha IS NULL AND @detalles IS NULL AND @activo IS NULL AND @nuevoCodigo IS NULL
    BEGIN
		RAISERROR('Debe indicar al menos un cambio.', 16, 1);
		RETURN;
	END

    IF @codigoNota NOT LIKE ('NC-2[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]')
	BEGIN
		RAISERROR('El formato de codigo de nota de crédito es inválido (NC-2YYY-000000).',16,1);
		RETURN;
	END

    IF NOT EXISTS (SELECT 1 FROM Ventas.NotaCredito WHERE codigoNota = @codigoNota)
    BEGIN
		RAISERROR('La nota de crédito no existe.',16,1);
		RETURN;
	END
    
    IF @cliente NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
	BEGIN
		RAISERROR('El formato del nuevo cliente es inválido.',16,1)
		RETURN;
	END

    SET @idCliente = (SELECT idCliente FROM Ventas.Cliente WHERE dniHASH = HASHBYTES('SHA2_256', @cliente) AND activo = 1)
    IF @idCliente IS NULL AND @cliente IS NULL
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

    IF @activo NOT IN (0,1)
    BEGIN
         RAISERROR('Activo solo puede tener los valores 0 y 1.', 16, 1);
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
        detalles          = ISNULL(@detalles, detalles),
        @activo           = ISNULL(@activo, activo)
    WHERE codigoNota = @codigoNota;
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Ventas.EliminarNotaCredito_sp
    @codigoNota  CHAR(14)
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
-- ABN Ventas.DetalleNota
CREATE OR ALTER PROCEDURE Ventas.InsertarDetalleNota_sp
    @codigoNota     CHAR(14),
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

    SET @idNota = (SELECT 1 FROM Ventas.NotaCredito WHERE codigoNota = @codigoNota AND activo = 1)
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

    SET @idDetalleFactura = (SELECT 1 FROM Ventas.DetalleFactura WHERE idFactura = @idFactura AND idProducto = @idProducto)
    IF @idDetalleFactura IS NULL
    BEGIN
        RAISERROR('El producto no está en la factura.', 16, 1);
    	RETURN;
	END

    -- Recuperamos precioUnitario y cantidad del detalle de la factura
    SET @precioUnitario = (SELECT @precioUnitario FROM Ventas.DetalleFactura WHERE idFactura = @idFactura AND idDetalleFactura = @idDetalleFactura)
    SET @cantidadTotal = (SELECT cantidad FROM Ventas.DetalleFactura WHERE idFactura = @idFactura AND idDetalleFactura = @idDetalleFactura)

    SET @cantidadDevuelta = (SELECT SUM(cantidad) FROM Ventas.DetalleNota WHERE idNota = @idNota AND idProducto = @idProducto)

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
CREATE OR ALTER PROCEDURE Ventas.ActualizarDetalleNota_sp
    @codigoNota     CHAR(14),
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
    SET @precioUnitario = (SELECT @precioUnitario FROM Ventas.DetalleNota WHERE idNota = @idNota AND idDetalleNota = @numDetalle)
    
	-- Monto total de la nota de crédito sin contar el detalle actual actualizado
    SET @montoSinDetalle = (SELECT monto FROM Ventas.NotaCredito WHERE idNota = @idNota) - @precioUnitario * (SELECT cantidad FROM Ventas.DetalleNota WHERE idNota = @idNota AND idDetalleNota = @numDetalle)

    -- Actualizamos precioUnitario si se actualiza el producto
    IF @producto IS NOT NULL
        SET @precioUnitario = (SELECT @precioUnitario FROM Ventas.DetalleFactura WHERE idFactura = @idFactura AND idDetalleFactura = @idDetalleFactura)
    
	-- Cantidad devuelta acumulada del producto en todas las notas de crédito de la factura
    SET @cantidadDevuelta = (SELECT SUM(cantidad) FROM Ventas.DetalleNota WHERE idNota = @idNota AND idProducto = @idProducto)

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
CREATE OR ALTER PROCEDURE Ventas.EliminarDetalleNota_sp
    @codigoNota     CHAR(14),
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
CREATE OR ALTER PROCEDURE Utilidades.ResetearTablas_sp
AS
BEGIN
    SET NOCOUNT ON;

	-- Vaciar tablas
    DELETE FROM Empresa.Cargo;
    DELETE FROM Empresa.Turno;
    DELETE FROM Empresa.Sucursal;
    DELETE FROM Empresa.Empleado;
    DELETE FROM Inventario.Producto;
    DELETE FROM Inventario.LineaProducto;
    DELETE FROM Ventas.Cliente;
    DELETE FROM Ventas.MedioPago;
    DELETE FROM Ventas.DetalleFactura;
    DELETE FROM Ventas.DetalleNota;
    DELETE FROM Ventas.Factura;
    DELETE FROM Ventas.NotaCredito;
    
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
