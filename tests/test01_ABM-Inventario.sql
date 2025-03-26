/*
Aurora SA
Tests de procedimientos ABM de esquema Inventario
GRodriguezAR
*/

Use [AuroraSA_DB]
GO

----------------------------------------------------------------------------------------------------------------
-- LineaProducto

EXEC Inventario.InsertarLineaProducto_sp 'Almacen'
EXEC Inventario.InsertarLineaProducto_sp 'Frescos'
SELECT * FROM Inventario.LineaProducto
-- Inserciones normales

EXEC Inventario.InsertarLineaProducto_sp 'Almacen'
-- Error: Codigo linea repetida

EXEC Inventario.InsertarLineaProducto_sp ''
-- Error: Descripcion vacia

EXEC Inventario.ActualizarLineaProducto_sp 'Frescos', 'Frutas y verduras'
SELECT * FROM Inventario.LineaProducto
-- Actualización de linea

EXEC Inventario.ActualizarLineaProducto_sp 'Carnes', 'Frutas y verduras'
-- Error: Linea inexistente

EXEC Inventario.EliminarLineaProducto_sp 'Almacen'
SELECT * FROM Inventario.LineaProducto
-- Borrado lógico

EXEC Inventario.ReactivarLineaProducto_sp 'Almacen'
SELECT * FROM Inventario.LineaProducto
-- Reactivación

----------------------------------------------------------------------------------------------------------------
-- Producto

EXEC Inventario.InsertarProducto_sp 'Aceite de oliva 500ml', 150.2, 'Almacen'
EXEC Inventario.InsertarProducto_sp 'Sal de mesa 250gr', 15.2, 'Almacen'
EXEC Inventario.InsertarProducto_sp 'Manzana', 17.2, 'Frutas y verduras'
SELECT nombreProducto, precioUnitario, descripcion, P.activo FROM Inventario.Producto P JOIN Inventario.LineaProducto ON idLineaProd = idLineaProducto
-- Inserciones normales

EXEC Inventario.InsertarProducto_sp 'Aceite de oliva 500ml', 150.2, 'Almacen'
-- Error: Producto existente

EXEC Inventario.InsertarProducto_sp 'Pimienta negra', -150.2, 'Almacen'
-- Error: Precio inválido

EXEC Inventario.InsertarProducto_sp 'Pimienta negra', 20.7, 'Condimentos'
-- Error: Linea de producto inexistente

EXEC Inventario.ActualizarProducto_sp @nombreProducto = 'Sal de mesa 250gr', @precioUnitario = 19.3
SELECT nombreProducto, precioUnitario, descripcion, P.activo FROM Inventario.Producto P JOIN Inventario.LineaProducto ON idLineaProd = idLineaProducto
-- Actualización de precio

EXEC Inventario.ActualizarProducto_sp @nombreProducto = 'Sal de mesa 250gr', @nuevoNombreProd = 'Aceite de oliva 500ml'
-- Error: Producto ya existente

EXEC Inventario.EliminarProducto_sp 'Sal de mesa 250gr'
SELECT * FROM Inventario.Producto
-- Borrado lógico

EXEC Inventario.ReactivarProducto_sp 'Sal de mesa 250gr'
SELECT * FROM Inventario.Producto
-- Reactivación


----------------------------------------------------------------------------------------------------------------
EXEC Utilidades.ResetearTablas_sp 
-- Borrar tablas y reiniciar identitys.
----------------------------------------------------------------------------------------------------------------


