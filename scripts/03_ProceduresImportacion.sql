/*
Aurora SA
Script de creacion de procedures de importación masiva
GRodriguezAR
*/

---------------------------------------------------------------------------------------------------------------------------
-- Importacion de catalogo.csv
CREATE PROCEDURE Inventario.CargarProductosCatalogoCSV_sp
    @rutaCatalogo      NVARCHAR(MAX),
    @rutaComplemento   NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
	BEGIN TRY
		-- Crear tabla temporal para cargar los datos del CSV
		CREATE TABLE #TempProductos (
			[id] INT,
			[category] NVARCHAR(50) COLLATE Modern_Spanish_CS_AS,
			[name] NVARCHAR(110) COLLATE Modern_Spanish_CI_AI,  
			[price] DECIMAL(10,2),
			[reference_price] DECIMAL(10,2),
			[reference_unit] VARCHAR(10) COLLATE Modern_Spanish_CS_AS,
			[date] DATETIME 
		);

		-- Índice no clúster para acelerar búsquedas por nombre
		CREATE NONCLUSTERED INDEX ix_tempNombreInclude ON #TempProductos([name]) INCLUDE ([price], [date], [category]);

		-- Crear tabla temporal para buscar coincidencias de línea de producto
		CREATE TABLE #TempEquivalenciaLineas (
			lineaVieja NVARCHAR(50) COLLATE Modern_Spanish_CS_AS PRIMARY KEY CLUSTERED,
			lineaNueva NVARCHAR(25) COLLATE Modern_Spanish_CS_AS
		);

		-- Importar el archivo CSV
		DECLARE @sql NVARCHAR(MAX);
		SET @sql = '
		BULK INSERT #TempProductos
		FROM ''' + @rutaCatalogo + '''
		WITH (
			FORMAT = ''CSV'', 
			FIRSTROW = 2, 
			FIELDTERMINATOR = '','', 
			ROWTERMINATOR = ''0x0A'',
			CODEPAGE = ''65001'',
			TABLOCK
		);
		';
		EXEC sp_executesql @sql;

		-- Importar el archivo de equivalencias de línea producto
		SET @sql = '	
			INSERT INTO #TempEquivalenciaLineas (lineaNueva, lineaVieja)
			SELECT *
			FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
				''Excel 12.0 Xml;HDR=YES;Database=' + @rutaComplemento + ''',
				''SELECT * FROM [Clasificacion productos$B1:C]'');
		';
		EXEC sp_executesql @sql;

		BEGIN TRANSACTION;
		-- Insertar nuevas líneas de producto que no existen en la tabla definitiva
		INSERT INTO Inventario.LineaProducto(descripcion)
		SELECT DISTINCT E.lineaNueva
		FROM #TempEquivalenciaLineas E
			LEFT JOIN Inventario.LineaProducto LP ON E.lineaNueva = LP.descripcion
		WHERE LP.idLineaProd IS NULL;

		-- Filtrar duplicados: quedarse solo con el registro más reciente para cada producto
		WITH ProductosFiltrados AS (
			SELECT 
				[name], 
				[category],
				[price],
				[date],
				ROW_NUMBER() OVER (PARTITION BY [name] ORDER BY [date] DESC) AS rn
			FROM #TempProductos 
		)
		-- Insertar productos con el precio más reciente
		INSERT INTO Inventario.Producto(nombreProducto, idLineaProducto, precioUnitario)
		SELECT 
			PF.[name], 
			LP.idLineaProd, 
			PF.price
		FROM ProductosFiltrados PF
			JOIN #TempEquivalenciaLineas E ON PF.category = E.lineaVieja 
			JOIN Inventario.LineaProducto LP ON E.lineaNueva = LP.descripcion
		WHERE PF.rn = 1 
			AND NOT EXISTS (SELECT 1 FROM Inventario.Producto P WHERE P.nombreProducto = PF.[name]);	-- Verifica que el producto no exista

		-- Limpiar tablas temporales
		DROP TABLE #TempEquivalenciaLineas;
		DROP TABLE #TempProductos;

		COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
		IF OBJECT_ID('tempdb..#TempEquivalenciaLineas') IS NOT NULL DROP TABLE #TempEquivalenciaLineas;
		IF OBJECT_ID('tempdb..#TempProductos') IS NOT NULL DROP TABLE #TempProductos;
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Error en Inventario.CargarProductosCatalogoCSV_sp: %s', 16, 1, @ErrorMsg);
    END CATCH;
END;
GO

-----------------------------------------------------------------------------------------------
-- Importacion de productos electronicos
CREATE PROCEDURE Inventario.CargarProductosElectronicos_sp
    @rutaCatalogo NVARCHAR(MAX),
	@valorDolar	  DECIMAL(10,2)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

	BEGIN TRY
		-- Verificar existencia de la línea de producto "Electronico"
		DECLARE @idLineaProd INT = (SELECT idLineaProd FROM Inventario.LineaProducto WHERE descripcion = 'Electronico');
		IF @idLineaProd IS NULL
		BEGIN 
			EXEC Inventario.InsertarLineaProducto_sp 'Electronico'
			SET @idLineaProd = (SELECT idLineaProd FROM Inventario.LineaProducto WHERE descripcion = 'Electronico');
		END

		-- Crear tabla temporal para cargar datos desde Excel
		CREATE TABLE #TempProductos (
			nombre NVARCHAR(110) COLLATE Modern_Spanish_CI_AI,
			precio DECIMAL(10,2)
		);
		CREATE NONCLUSTERED INDEX ix_tempNombre ON #TempProductos(nombre) INCLUDE (precio)

		-- Importar datos desde el archivo XLSX
		DECLARE @sql NVARCHAR(MAX);
		SET @sql = '
			INSERT INTO #TempProductos (nombre, precio)
			SELECT *
			FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
				''Excel 12.0 Xml;HDR=YES;Database=' + @rutaCatalogo + ''',
				''SELECT * FROM [Sheet1$B1:C]'');
		';
		EXEC sp_executesql @sql;

		BEGIN TRANSACTION;
		-- Filtrar duplicados: quedarse solo con el registro con el precio máximo (o más reciente)
		WITH ElecFiltrados AS (
			SELECT *,
				ROW_NUMBER() OVER(PARTITION BY nombre ORDER BY precio desc) rn
			FROM #TempProductos
		)
		INSERT INTO Inventario.Producto(nombreProducto, idLineaProducto, precioUnitario)
		SELECT 
			nombre AS nombre,
			@idLineaProd AS lineaProducto,          
			precio*@valorDolar AS precioUnitario               
		FROM ElecFiltrados 
		WHERE rn = 1
			AND NOT EXISTS (SELECT 1 FROM Inventario.Producto P WHERE P.nombreProducto = nombre);

		DROP TABLE #TempProductos;
		COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
		IF OBJECT_ID('tempdb..#TempProductos') IS NOT NULL DROP TABLE #TempProductos;
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Error en Inventario.CargarProductosElectronicos_sp: %s', 16, 1, @ErrorMsg);
    END CATCH;
END
GO

--------------------------------------------------------------------------------
-- Importacion de productos importados
CREATE PROCEDURE Inventario.CargarProductosImportados_sp
    @rutaCatalogo		NVARCHAR(MAX),
	@rutaComplemento	NVARCHAR(MAX),
	@valorDolar			DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

	BEGIN TRY
		-- Crear tabla temporal para cargar datos del XLSX
		CREATE TABLE #TempProductos (
			idProducto INT,
			NombreProducto NVARCHAR(100) COLLATE Modern_Spanish_CI_AI,
			Proveedor NVARCHAR(100) COLLATE Modern_Spanish_CS_AS,
			Categoria NVARCHAR(30) COLLATE Modern_Spanish_CS_AS,
			CantidadPorUnidad VARCHAR(20) COLLATE Modern_Spanish_CS_AS,
			PrecioUnidad DECIMAL(10,2) -- Se importa como texto
		);
		CREATE NONCLUSTERED INDEX ix_tempNombre ON #TempProductos(NombreProducto, PrecioUnidad) INCLUDE (Categoria);

		-- Inserción desde el archivo XLSX
		DECLARE @sql NVARCHAR(MAX);
		SET @sql = '
			INSERT INTO #TempProductos (idProducto, NombreProducto, Proveedor, Categoria, CantidadPorUnidad, PrecioUnidad)
			SELECT IdProducto, NombreProducto, Proveedor, Categoría, CantidadPorUnidad, CAST(PrecioUnidad AS DECIMAL(10,2))
			FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
				''Excel 12.0 Xml;HDR=YES;IMEX=1;Locale Identifier=1033;Database=' + @rutaCatalogo + ''',
				''SELECT * FROM [Listado De Productos$]'')
		';
		EXEC dbo.sp_executesql @sql;
	
		-- Crear tabla temporal para equivalencias
		CREATE TABLE #TempEquivalenciaLineas (
			lineaVieja NVARCHAR(50) COLLATE Modern_Spanish_CS_AS PRIMARY KEY CLUSTERED,	-- Se encuentra ordenado en el archivo origen por lo que la insercion es eficiente
			lineaNueva NVARCHAR(25) COLLATE Modern_Spanish_CS_AS
		);

		SET @sql = '
			INSERT INTO #TempEquivalenciaLineas (lineaNueva, lineaVieja)
			SELECT *
			FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
				''Excel 12.0 Xml;HDR=YES;Database=' + @rutaComplemento + ''',
				''SELECT * FROM [Clasificacion productos$B1:C]'');
		';
		EXEC sp_executesql @sql;
		
		BEGIN TRANSACTION;
		-- Insertar nuevas líneas de producto (si no existen)
		INSERT INTO Inventario.LineaProducto(descripcion)
		SELECT DISTINCT E.lineaNueva
		FROM #TempEquivalenciaLineas E
			LEFT JOIN Inventario.LineaProducto LP ON E.lineaNueva = LP.descripcion
		WHERE LP.idLineaProd IS NULL;

		-- Filtrar duplicados: quedarse solo con el registro con el precio máximo
		WITH ImpFiltrados AS (
			SELECT NombreProducto, Categoria, PrecioUnidad,
				ROW_NUMBER() OVER(PARTITION BY NombreProducto ORDER BY precioUnidad DESC) rn
			FROM #TempProductos
		)
		INSERT INTO Inventario.Producto(nombreProducto, idLineaProducto, precioUnitario)
		SELECT 
			F.NombreProducto,
			LP.idLineaProd, 
			F.PrecioUnidad
		FROM ImpFiltrados F
			LEFT JOIN #TempEquivalenciaLineas E ON F.Categoria = E.lineaVieja 
			LEFT JOIN Inventario.LineaProducto LP ON E.lineaNueva = LP.descripcion
		WHERE F.rn = 1 
			AND NOT EXISTS (SELECT 1 FROM Inventario.Producto P WHERE P.nombreProducto = F.NombreProducto);	-- Verifica que el producto no exista

		DROP TABLE #TempEquivalenciaLineas;
		DROP TABLE #TempProductos;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF OBJECT_ID('tempdb..#TempProductos') IS NOT NULL DROP TABLE #TempProductos;
		IF OBJECT_ID('tempdb..#TempEquivalenciaLineas') IS NOT NULL DROP TABLE #TempEquivalenciaLineas;
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Error en Inventario.CargarProductosImportados_sp: %s', 16, 1, @ErrorMsg);
    END CATCH;
END
GO

-----------------------------------------------------------------------------------------------
-- Importacion de sucursales
CREATE PROCEDURE Empresa.ImportarSucursales_sp
    @rutaArchivo NVARCHAR(MAX) 
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

	BEGIN TRY
		-- Crear tabla temporal para cargar datos del XLSX
		CREATE TABLE #TempSucursales (
			codigoSucursal VARCHAR(25) COLLATE Modern_Spanish_CS_AS,
			ciudad NVARCHAR(100) COLLATE Modern_Spanish_CS_AS,
			direccion NVARCHAR(100) COLLATE Modern_Spanish_CI_AI,  
			horario NVARCHAR(100) COLLATE Modern_Spanish_CI_AI,
			telefono NVARCHAR(100) COLLATE Modern_Spanish_CI_AI
		);
		CREATE NONCLUSTERED INDEX ix_tempCodigo ON #TempSucursales(codigoSucursal)

		-- Inserción desde archivo XLSX
		DECLARE @sql NVARCHAR(MAX);
		SET @sql = '
			INSERT INTO #TempSucursales (codigoSucursal, ciudad, direccion, horario, telefono)
			SELECT *
			FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
				''Excel 12.0 Xml;HDR=YES;IMEX=1;Database=' + @rutaArchivo + ''',
				''SELECT * FROM [sucursal$B2:F]'');
		';
		EXEC sp_executesql @sql;

		BEGIN TRANSACTION;
		-- Filtrar duplicados
		WITH SucFiltrados AS (
			SELECT *,
				ROW_NUMBER() OVER(PARTITION BY codigoSucursal ORDER BY (SELECT NULL)) rn
			FROM #TempSucursales
		)
		INSERT INTO Empresa.Sucursal (codigoSucursal, ciudad, direccion, horario, telefono)
		SELECT 
			codigoSucursal,
			ciudad,
			direccion,
			horario,
			telefono            
		FROM SucFiltrados 
		WHERE rn = 1
			AND NOT EXISTS (SELECT 1 FROM Empresa.Sucursal S WHERE S.codigoSucursal = codigoSucursal);

		DROP TABLE #TempSucursales; 
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF OBJECT_ID('tempdb..#TempSucursales') IS NOT NULL DROP TABLE #TempSucursales;
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Error en Empresa.ImportarSucursales_sp: %s', 16, 1, @ErrorMsg);
    END CATCH;
END;
GO

-----------------------------------------------------------------------------------------------
-- Importacion de turnos
CREATE PROCEDURE Empresa.ImportarTurnos_sp
    @rutaArchivo NVARCHAR(MAX) 
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

	BEGIN TRY
		-- Crear tabla temporal para cargar datos del XLSX
		CREATE TABLE #TempTurnos (
			acronimo VARCHAR(25) COLLATE Modern_Spanish_CS_AS,
			descripcion NVARCHAR(100) COLLATE Modern_Spanish_CS_AS
		);
		CREATE NONCLUSTERED INDEX ix_tempCodigo ON #TempTurnos(acronimo)

		-- Inserción de archivo XLSX
		DECLARE @sql NVARCHAR(MAX);
		SET @sql = '
			INSERT INTO #TempTurnos (acronimo, descripcion)
			SELECT *
			FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
				''Excel 12.0 Xml;HDR=YES;IMEX=1;Database=' + @rutaArchivo + ''',
				''SELECT * FROM [turnos$B2:C]'');
		';
		EXEC sp_executesql @sql;

		BEGIN TRANSACTION;
		-- Filtrar duplicados
		WITH TurFiltrados AS (
			SELECT *,
				ROW_NUMBER() OVER(PARTITION BY acronimo ORDER BY (SELECT NULL)) rn
			FROM #TempTurnos
		)
		INSERT INTO Empresa.Turno (acronimo, descripcion)
		SELECT 
			acronimo,
			descripcion        
		FROM TurFiltrados 
		WHERE rn = 1
			AND NOT EXISTS (SELECT 1 FROM Empresa.Turno T WHERE T.acronimo = acronimo);

		DROP TABLE #TempTurnos;
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF OBJECT_ID('tempdb..#TempTurnos') IS NOT NULL DROP TABLE #TempTurnos;
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Error en Empresa.ImportarTurnos_sp: %s', 16, 1, @ErrorMsg);
    END CATCH;
END;
GO

-----------------------------------------------------------------------------------------------
-- Importacion de cargos
CREATE PROCEDURE Empresa.ImportarCargos_sp
    @rutaArchivo NVARCHAR(MAX) 
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

	BEGIN TRY
		-- Crear tabla temporal para cargar datos del XLSX
		CREATE TABLE #TempCargos (
			nombre VARCHAR(25) COLLATE Modern_Spanish_CS_AS,
			descripcion NVARCHAR(200) COLLATE Modern_Spanish_CS_AS
		);
		CREATE NONCLUSTERED INDEX ix_tempCodigo ON #TempCargos(nombre)

		-- Inserción de archivo XLSX
		DECLARE @sql NVARCHAR(MAX);
		SET @sql = '
			INSERT INTO #TempCargos (nombre, descripcion)
			SELECT *
			FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
				''Excel 12.0 Xml;HDR=YES;IMEX=1;Database=' + @rutaArchivo + ''',
				''SELECT * FROM [cargos$B2:C]'');
		';
		EXEC sp_executesql @sql;

		BEGIN TRANSACTION;
		-- Filtrado de duplicados
		WITH CarFiltrados AS (
			SELECT *,
				ROW_NUMBER() OVER(PARTITION BY nombre ORDER BY (SELECT NULL)) rn
			FROM #TempCargos
		)
		INSERT INTO Empresa.Cargo (nombre, descripcion)
		SELECT 
			nombre,
			descripcion        
		FROM CarFiltrados 
		WHERE rn = 1
			AND NOT EXISTS (SELECT 1 FROM Empresa.Cargo C WHERE C.nombre = nombre);

		DROP TABLE #TempCargos; 
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF OBJECT_ID('tempdb..#TempCargos') IS NOT NULL DROP TABLE #TempCargos;
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Error en Empresa.ImportarCargos_sp: %s', 16, 1, @ErrorMsg);
    END CATCH;
END;
GO
-----------------------------------------------------------------------------------------------
-- Importacion de medios de pago
CREATE PROCEDURE Ventas.ImportarMedios_sp
    @rutaArchivo NVARCHAR(MAX) 
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

	BEGIN TRY
		-- Crear tabla temporal para cargar datos del XLSX
		CREATE TABLE #TempMedios (
			nombre NVARCHAR(40) COLLATE Modern_Spanish_CS_AS
		);
		CREATE NONCLUSTERED INDEX ix_tempMedios ON #TempMedios(nombre)

		-- Inserción desde archivo XLSX
		DECLARE @sql NVARCHAR(MAX);
		SET @sql = '
			INSERT INTO #TempMedios (nombre)
			SELECT *
			FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
				''Excel 12.0 Xml;HDR=YES;IMEX=1;Database=' + @rutaArchivo + ''',
				''SELECT * FROM [medios de pago$B2:B]'');
		';
		EXEC sp_executesql @sql;

		BEGIN TRANSACTION;
		-- Filtrado de duplicados
		WITH MedFiltrados AS (
			SELECT *,
				ROW_NUMBER() OVER(PARTITION BY nombre ORDER BY (SELECT NULL)) rn
			FROM #TempMedios
		)
		INSERT INTO Ventas.MedioPago (nombre)
		SELECT nombre
		FROM MedFiltrados 
		WHERE rn = 1
			AND NOT EXISTS (SELECT 1 FROM Ventas.MedioPago M WHERE M.nombre = nombre);

		DROP TABLE #TempMedios; 
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF OBJECT_ID('tempdb..#TempMedios') IS NOT NULL DROP TABLE #TempMedios;
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Error en Empresa.ImportarMedios_sp: %s', 16, 1, @ErrorMsg);
    END CATCH;
END;
GO
 -----------------------------------------------------------------------------------------------
-- Importacion de empleados
CREATE PROCEDURE Empresa.ImportarEmpleados_sp
    @rutaArchivo NVARCHAR(MAX) 
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
	--DECLARE @rutaArchivo NVARCHAR(MAX) = 'E:\Proyectos\AuroraSA-DB\data\Informacion_complementaria.xlsx'
	BEGIN TRY
		-- Crear tabla temporal para cargar datos del XLSX
		CREATE TABLE #TempEmpleados (
			legajo			INT,
			nombre			VARCHAR(30) COLLATE Modern_Spanish_CS_AS,
			apellido		VARCHAR(30) COLLATE Modern_Spanish_CS_AS,
			genero			VARCHAR(30) COLLATE Modern_Spanish_CS_AS,
			cuil			VARCHAR(30)	COLLATE Modern_Spanish_CS_AS,
			telefono		VARCHAR(30)	COLLATE Modern_Spanish_CS_AS,
			domicilio		NVARCHAR(100) COLLATE Modern_Spanish_CS_AS,
			fechaAlta		VARCHAR(100) COLLATE Modern_Spanish_CS_AS,
			mailPersonal	VARCHAR(55) COLLATE Modern_Spanish_CS_AS,
			mailEmpresa		VARCHAR(55) COLLATE Modern_Spanish_CS_AS,
			cargo			VARCHAR(25) COLLATE Modern_Spanish_CS_AS,
			sucursal		VARCHAR(30) COLLATE Modern_Spanish_CS_AS,
			turno			VARCHAR(20) COLLATE Modern_Spanish_CS_AS
		);
		CREATE CLUSTERED INDEX ix_tempLegajo ON #TempEmpleados(legajo);

		-- Inserción de archivo XLSX
		DECLARE @cadenaSql NVARCHAR(MAX)
		SET @cadenaSql = '
			INSERT INTO #TempEmpleados (legajo, nombre, apellido, genero, cuil, telefono, domicilio, fechaAlta, mailPersonal, mailEmpresa, cargo, sucursal, turno)
			SELECT Legajo, Nombre, Apellido, Genero, Cuil, Telefono, Direccion, FechaAlta, EmailPersonal, EmailEmpresa, Cargo, Sucursal, Turno
			FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
				''Excel 12.0 Xml;HDR=YES;IMEX=1;Database=' + @rutaArchivo + ''',
				''SELECT * FROM [empleados$]'');
		';
		EXEC sp_executesql @cadenaSql;
		
		BEGIN TRANSACTION;
		-- Filtramos duplicados, insertamos campos encriptados.
		WITH EmpFiltrados AS (
			SELECT *,
				HASHBYTES('SHA2_512', cuil) as cuilHASH,
				ROW_NUMBER() OVER (PARTITION BY cuil ORDER BY (SELECT NULL)) rn1,
				ROW_NUMBER() OVER (PARTITION BY legajo ORDER BY (SELECT NULL)) rn2
			 FROM #TempEmpleados
		) 
		INSERT INTO Empresa.Empleado (legajo, nombre, apellido, genero, cuil, cuilHASH, telefono, domicilio, fechaAlta, mailPersonal, mailEmpresa, idCargo, idSucursal, idTurno)
		SELECT
			E.legajo,
			E.nombre,
			E.apellido,
			UPPER(SUBSTRING(E.genero,1,1)),
			EncryptByKey(Key_GUID('LlaveSimetrica'), E.cuil),
			E.cuilHASH,
			EncryptByKey(Key_GUID('LlaveSimetrica'), E.telefono),
			EncryptByKey(Key_GUID('LlaveSimetrica'), E.domicilio),
			E.fechaAlta,
			EncryptByKey(Key_GUID('LlaveSimetrica'), LOWER(E.mailPersonal)),
			LOWER(E.mailEmpresa),
			C.idCargo,
			S.idSucursal,
			T.idTurno
		FROM EmpFiltrados E
			JOIN Empresa.Sucursal S ON E.sucursal = S.codigoSucursal
			JOIN Empresa.Cargo C	ON E.cargo	  = C.nombre
			JOIN Empresa.Turno T	ON E.turno	  = T.acronimo
		WHERE E.rn1 = 1	AND E.rn2 = 1
			AND NOT EXISTS (SELECT 1 FROM Empresa.Empleado EE WHERE EE.cuilHASH = E.cuilHASH) 	
			AND NOT EXISTS (SELECT 1 FROM Empresa.Empleado EE WHERE EE.legajo = E.legajo);					   
 
		DROP TABLE #TempEmpleados
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF OBJECT_ID('tempdb..#TempEmpleados') IS NOT NULL DROP TABLE #TempEmpleados;
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Error en Empresa.ImportarEmpleados_sp: %s', 16, 1, @ErrorMsg);
    END CATCH;
END;
GO

--------------------------------------------------------------------------------
-- Importacion de clientes
CREATE PROCEDURE Ventas.ImportarClientes_sp
	@rutaArchivo NVARCHAR(MAX) 
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

	BEGIN TRY
		-- Crear tabla temporal para cargar datos XLSX
		CREATE TABLE #TempClientes (
			nombre VARCHAR(30) COLLATE Modern_Spanish_CS_AS,
			apellido VARCHAR(30) COLLATE Modern_Spanish_CS_AS,
			genero VARCHAR(30) COLLATE Modern_Spanish_CS_AS,
			dni	VARCHAR(30) COLLATE Modern_Spanish_CS_AS,
			tipoCliente VARCHAR(30) COLLATE Modern_Spanish_CS_AS,
			puntos INT
		);
		CREATE CLUSTERED INDEX ix_tempClienteDni ON #TempClientes(dni);
		
		-- Inserción de archivo XLSX
		DECLARE @sql NVARCHAR(MAX);
		SET @sql = '
			INSERT INTO #TempClientes (nombre, apellido, genero, dni, tipoCliente, puntos)
			SELECT Nombre, Apellido, Genero, FORMAT(Dni, ''0''), Tipo, Puntos
			FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
				''Excel 12.0 Xml;HDR=YES;IMEX=1;Database=' + @rutaArchivo + ''',
				''SELECT * FROM [clientes$]'');
		';
		EXEC sp_executesql @sql;
		
		BEGIN TRANSACTION;
		-- Filtrar duplicados, se insertan campos encriptados
		WITH CliFiltrados AS (
			SELECT *,
				HASHBYTES('SHA2_256',dni) as dniHASH,		
				ROW_NUMBER() OVER(PARTITION BY dni ORDER BY (SELECT NULL)) rn
			FROM #TempClientes
			WHERE dni IS NOT NULL AND LEN(dni) > 0
		)
		INSERT INTO Ventas.Cliente (nombre, apellido, dni, dniHASH, genero, tipoCliente, puntos, fechaAlta)
		SELECT 
			CF.nombre,
			CF.apellido,
			EncryptByKey(Key_GUID('LlaveSimetrica'),CF.dni),
			CF.dniHASH,
			SUBSTRING(CF.genero,1,1),
			CF.tipoCliente,
			TRY_CONVERT(INT, CF.puntos) AS puntos,
			GETDATE()
		FROM CliFiltrados CF
		WHERE CF.rn = 1
			AND NOT EXISTS (SELECT 1 FROM Ventas.Cliente C WHERE C.dniHASH = CF.dniHASH);

		DROP TABLE #TempClientes;
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF OBJECT_ID('tempdb..#TempClientes') IS NOT NULL DROP TABLE #TempClientes;
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Error en Empresa.ImportarClientes_sp: %s', 16, 1, @ErrorMsg);
    END CATCH;
END;
GO

--------------------------------------------------------------------------------
-- Importacion de ventas
CREATE PROCEDURE Ventas.ImportarVentas_sp
    @rutaArchivo NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

	BEGIN TRY
		-- Crear tabla temporal para cargar datos del CSV
		CREATE TABLE #TempVentas (
			CodigoFactura VARCHAR(30) COLLATE Modern_Spanish_CS_AS,
			TipoFactura VARCHAR(20) COLLATE Modern_Spanish_CS_AS,
			Sucursal VARCHAR(20) COLLATE Modern_Spanish_CS_AS,
			Cliente VARCHAR(20) COLLATE Modern_Spanish_CS_AS,
			Producto NVARCHAR(100) COLLATE Modern_Spanish_CI_AI,
			Precio DECIMAL(10,2),
			Cantidad INT,
			FechaHora DATETIME,
			MedioPago VARCHAR(30) COLLATE Modern_Spanish_CS_AS,
			Empleado INT,
			DetallesPago VARCHAR(100) COLLATE Modern_Spanish_CS_AS
		);
		CREATE CLUSTERED INDEX ix_tempCodFact ON #TempVentas(CodigoFactura)

		-- Inserción de archivo CSV
		DECLARE @sql NVARCHAR(MAX);
		SET @sql = '
		BULK INSERT #TempVentas
		FROM ''' + @rutaArchivo + '''
		WITH (
			FORMAT = ''CSV'', 
			FIRSTROW = 2, 
			FIELDTERMINATOR = '','', 
			ROWTERMINATOR = ''\n'',
			CODEPAGE = ''65001'',
			TABLOCK
		);
		';
		EXEC sp_executesql @sql

		-- Calcular el total de cada factura
		CREATE TABLE #TotalesPorFactura (
			codigoFactura CHAR(11) COLLATE Modern_Spanish_CS_AS PRIMARY KEY,
			total DECIMAL(10, 2) 
		);

		INSERT INTO #TotalesPorFactura (codigoFactura, total)
		SELECT CodigoFactura, SUM(Precio * Cantidad) AS total
		FROM #TempVentas
		GROUP BY CodigoFactura;

		BEGIN TRANSACTION;

		-- Cliente 0 corresponde a un cliente no registrado, se inserta en caso de que no exista
		OPEN SYMMETRIC KEY LlaveSimetrica DECRYPTION BY CERTIFICATE CertificadoSeguridad; 
		IF NOT EXISTS (SELECT 1 FROM Ventas.Cliente WHERE dniHASH = HASHBYTES('SHA2_256', '0'))
			EXEC Ventas.InsertarCliente_sp '0','No registrado', 'N/A','M','Normal'
		CLOSE SYMMETRIC KEY LlaveSimetrica;

		-- Inserción en tabla de cada factura. (Se utiliza MAX ya que los campos se repiten por mismo codigo de factura)
		INSERT INTO Ventas.Factura (codigoFactura, tipoFactura, fecha, detallesPago, total, idMedioPago, idCliente, idEmpleado, idSucursal)
		SELECT 
			V.CodigoFactura,
			MAX(V.TipoFactura) as tipoFactura,
			MAX(V.FechaHora) as fecha,
			MAX(V.DetallesPago) as detallesPago,
			MAX(TF.total) as total,
			MAX(M.idMedio) as idMedio,
			MAX(C.idCliente) as idCliente,
			MAX(E.idEmpleado) as idEmpleado,
			MAX(S.idSucursal) as idSucursal
		FROM #TempVentas V
			JOIN #TotalesPorFactura TF ON V.CodigoFactura = TF.codigoFactura
			JOIN Ventas.MedioPago M ON V.MedioPago = M.nombre
			JOIN Ventas.Cliente C ON HASHBYTES('SHA2_256', V.Cliente) = C.dniHASH
			JOIN Empresa.Empleado E ON V.Empleado = E.legajo
			JOIN Empresa.Sucursal S ON V.Sucursal = S.codigoSucursal
		WHERE NOT EXISTS (SELECT 1 FROM Ventas.Factura f WHERE V.CodigoFactura = f.codigoFactura)
		GROUP BY V.codigoFactura;
	
		-- Creación de tabla para cada item de la factura
		CREATE TABLE #GruposDetalle (
			codigoFactura CHAR(11) COLLATE Modern_Spanish_CS_AS,
			numDetalle INT,
			nombreProd NVARCHAR(100) COLLATE Modern_Spanish_CI_AI,
			precioUnitario DECIMAL(10,2),
			cantidad INT,
			subtotal DECIMAL(10,2),
			CONSTRAINT tempPK_GruposVenta PRIMARY KEY (codigoFactura,numDetalle) 
		);
	
		-- Filtrado de duplicados y calculo de numero de detalle
		WITH VentaDetalle AS (
			SELECT 
				CodigoFactura, Producto, Precio, Cantidad, 
				ROW_NUMBER() OVER(PARTITION BY CodigoFactura ORDER BY (SELECT NULL)) as numDetalle
			FROM #TempVentas
		) 
		INSERT INTO Ventas.DetalleFactura (idFactura, idDetalleFactura, idProducto, cantidad, precioUnitario, subtotal)
		SELECT F.idFactura, V.numDetalle, P.idProducto, V.Cantidad, V.Precio, V.Cantidad * V.Precio as subtotal
		FROM VentaDetalle V JOIN Ventas.Factura F ON V.CodigoFactura = F.codigoFactura
							JOIN Inventario.Producto P ON V.Producto = P.nombreProducto
		WHERE NOT EXISTS (SELECT 1 FROM Ventas.DetalleFactura DF WHERE DF.idFactura = F.idFactura AND (DF.idProducto = P.idProducto OR DF.idDetalleFactura = V.numDetalle)) 

		DROP TABLE #TempVentas;
		DROP TABLE #TotalesPorFactura
		DROP TABLE #GruposDetalle

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF OBJECT_ID('tempdb..#TempVentas') IS NOT NULL DROP TABLE #TempVentas;
		IF OBJECT_ID('tempdb..#TotalesPorFactura') IS NOT NULL DROP TABLE #TotalesPorFactura;
		IF OBJECT_ID('tempdb..#GruposDetalle') IS NOT NULL DROP TABLE #GruposDetalle;
		IF EXISTS (SELECT 1 FROM sys.openkeys WHERE key_name = KEY_ID('LlaveSimetrica'))
			CLOSE SYMMETRIC KEY LlaveSimetrica;
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Error en Empresa.ImportarVentas_sp: %s', 16, 1, @ErrorMsg);
    END CATCH;
END
GO