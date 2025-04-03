/*
Aurora SA
Tests de importación con lotes de prueba
GRodriguezAR
*/


Use [AuroraSA_DB]
GO

----------------------------------------------------------------------------------------------------------------
-- Productos y lineas de producto

DECLARE @rutaComplemento	NVARCHAR(MAX) = 'E:\Proyectos\AuroraSA-DB\data\Informacion_complementaria.xlsx',
		@rutaCatalogo		NVARCHAR(MAX) = 'E:\Proyectos\AuroraSA-DB\data\Productos\catalogo.csv',
		@rutaElectronicos	NVARCHAR(MAX) = 'E:\Proyectos\AuroraSA-DB\data\Productos\Electronic accessories.xlsx',
		@rutaImportados		NVARCHAR(MAX) = 'E:\Proyectos\AuroraSA-DB\data\Productos\Productos_importados.xlsx',
		@valorDolar			DECIMAL(10,2) = 1;

EXEC Inventario.CargarProductosCatalogoCSV_sp @rutaCatalogo, @rutaComplemento
EXEC Inventario.CargarProductosElectronicos_sp @rutaElectronicos, @valorDolar
EXEC Inventario.CargarProductosImportados_sp @rutaImportados, @rutaComplemento, @valorDolar
SELECT * FROM Inventario.Producto
SELECT * FROM Inventario.LineaProducto

----------------------------------------------------------------------------------------------------------------
-- Turnos, cargos, sucursales y medios de pago

DECLARE @rutaArchivo NVARCHAR(MAX) = 'E:\Proyectos\AuroraSA-DB\data\Informacion_complementaria.xlsx'

EXEC Empresa.ImportarCargos_sp @rutaArchivo
EXEC Empresa.ImportarTurnos_sp	@rutaArchivo
EXEC Empresa.ImportarSucursales_sp @rutaArchivo
EXEC Ventas.ImportarMedios_sp @rutaArchivo

SELECT * FROM Empresa.Cargo
SELECT * FROM Empresa.Turno
SELECT * FROM Empresa.Sucursal
SELECT * FROM Ventas.MedioPago

----------------------------------------------------------------------------------------------------------------
-- Empleados

DECLARE @rutaArchivo NVARCHAR(MAX) = 'E:\Proyectos\AuroraSA-DB\data\Informacion_complementaria.xlsx'

-- Se van a insertar campos cifrados
OPEN SYMMETRIC KEY LlaveSimetrica DECRYPTION BY CERTIFICATE CertificadoSeguridad; 
EXEC Empresa.ImportarEmpleados_sp @rutaArchivo

SELECT * FROM Empresa.Empleado

-- Ver campos sin encriptar
SELECT idEmpleado, legajo, nombre, apellido, genero,
    CONVERT(VARCHAR, DECRYPTBYKEY(cuil)) AS cuil,
	CONVERT(VARCHAR, DECRYPTBYKEY(telefono)) AS telefono,
	CONVERT(NVARCHAR, DECRYPTBYKEY(domicilio)) AS domicilio, fechaAlta,
    CONVERT(VARCHAR, DECRYPTBYKEY(mailPersonal)) AS mailPersonal, mailEmpresa, idCargo, idSucursal, idTurno
FROM Empresa.Empleado;

CLOSE SYMMETRIC KEY LlaveSimetrica;

----------------------------------------------------------------------------------------------------------------
-- Clientes

DECLARE @rutaArchivo NVARCHAR(MAX) = 'E:\Proyectos\AuroraSA-DB\data\Informacion_complementaria.xlsx'

-- Se van a insertar campos cifrados
OPEN SYMMETRIC KEY LlaveSimetrica DECRYPTION BY CERTIFICATE CertificadoSeguridad; 
EXEC Ventas.ImportarClientes_sp @rutaArchivo

SELECT * FROM Empresa.Empleado

-- Ver campos sin encriptar
SELECT idCliente, nombre, apellido,
	   CONVERT(VARCHAR, DECRYPTBYKEY(dni)) AS dni, genero, tipoCliente, puntos, fechaAlta, activo
FROM Ventas.Cliente

CLOSE SYMMETRIC KEY LlaveSimetrica;

----------------------------------------------------------------------------------------------------------------
-- Facturas y detalles de factura

DECLARE @rutaArchivo NVARCHAR(MAX) = 'E:\Proyectos\AuroraSA-DB\data\facturas.csv'

EXEC Ventas.ImportarVentas_sp @rutaArchivo

SELECT TOP(50) * FROM Ventas.Factura