/*
Aurora SA
Tests de procedimientos ABM de esquema Ventas
*/

Use [AuroraSA_DB]
GO

----------------------------------------------------------------------------------------------------------------
-- Cliente

OPEN SYMMETRIC KEY LlaveSimetrica DECRYPTION BY CERTIFICATE CertificadoSeguridad;
-- Necesario para insertar campos encriptados


EXEC Ventas.InsertarCliente_sp '39425412', 'Matias', 'Gonzalez', 'M', 'Miembro'  
EXEC Ventas.InsertarCliente_sp '38741442', 'Giuliana', 'Maidana', 'F', 'Normal'  
SELECT * FROM Ventas.Cliente  -- Con dni encriptado

SELECT idCliente, nombre, apellido,
	   CONVERT(VARCHAR, DECRYPTBYKEY(dni)) AS dni, genero, tipoCliente, puntos, fechaAlta, activo
FROM Ventas.Cliente
-- Inserciones normales

EXEC Ventas.InsertarCliente_sp '39425412', 'Matias', 'Gonzalez', 'M', 'Miembro'
-- Error: Cliente existente

EXEC Ventas.InsertarCliente_sp '1234', 'Matias', 'Gonzalez', 'M', 'Miembro'
-- Error: Dni inválido

EXEC Ventas.InsertarCliente_sp '36425412', 'Matias', 'Gonzalez', 'M', 'Normal', 100
-- Error: Un cliente no miembro no puede tener puntos

EXEC Ventas.InsertarCliente_sp '36425412', 'Matias', 'Gonzalez', 'M', 'Jefe', 100
-- Error: Tipo de cliente inválido

EXEC Ventas.ActualizarCliente_sp @dni = '39425412', @puntos = 200
SELECT idCliente, nombre, apellido,
	   CONVERT(VARCHAR, DECRYPTBYKEY(dni)) AS dni, genero, tipoCliente, puntos, fechaAlta, activo
FROM Ventas.Cliente
-- Actualización de puntos de cliente

EXEC Ventas.ActualizarCliente_sp @dni = '39425412', @puntos = -150
-- Error: Puntos inválidos

EXEC Ventas.EliminarCliente_sp '39425412'
SELECT idCliente, nombre, apellido,
	   CONVERT(VARCHAR, DECRYPTBYKEY(dni)) AS dni, genero, tipoCliente, puntos, fechaAlta, activo
FROM Ventas.Cliente
-- Borrado lógico

EXEC Ventas.ReactivarCliente_sp '39425412'
SELECT idCliente, nombre, apellido,
	   CONVERT(VARCHAR, DECRYPTBYKEY(dni)) AS dni, genero, tipoCliente, puntos, fechaAlta, activo
FROM Ventas.Cliente
-- Reactivación

CLOSE SYMMETRIC KEY LlaveSimetrica;
-- Cerrar llave de cifrado.

----------------------------------------------------------------------------------------------------------------
-- MedioPago

EXEC Ventas.InsertarMedioPago_sp 'Efectivo'
EXEC Ventas.InsertarMedioPago_sp 'Crédito'
SELECT * FROM Ventas.MedioPago
-- Inserciones normales

EXEC Ventas.InsertarMedioPago_sp 'Crédito'
-- Error: Medio existente

EXEC Ventas.ActualizarMedioPago_sp 'Crédito', 'Débito'
SELECT * FROM Ventas.MedioPago
-- Actualizacion de nombre

EXEC Ventas.ActualizarMedioPago_sp 'Débito', '   '
-- Error: Nombre vacío


EXEC Inventario.InsertarProducto_sp 'Pimienta negra', 20.7, 'Condimentos'
-- Error: Linea de producto inexistente

EXEC Ventas.EliminarMedioPago_sp 'Débito'
SELECT * FROM Ventas.MedioPago
-- Borrado lógico

EXEC Ventas.ReactivarMedioPago_sp 'Débito'
SELECT * FROM Ventas.MedioPago
-- Reactivación


----------------------------------------------------------------------------------------------------------------
-- Factura

OPEN SYMMETRIC KEY LlaveSimetrica DECRYPTION BY CERTIFICATE CertificadoSeguridad;

EXEC Empresa.InsertarSucursal_sp 'RM1', 'Av. Rivadavia 12324', 'Ramos Mejia', '4075-8745','L a V 09 a 20'
EXEC Empresa.InsertarSucursal_sp 'RM2', 'Av. de Mayo 654', 'Ramos Mejia', '4123-5634','L a V 09 a 20'
EXEC Empresa.InsertarCargo_sp 'Cajero', 'Cajero de mostrador'
EXEC Empresa.InsertarTurno_sp 'TM', 'Turno mañana'
EXEC Empresa.InsertarTurno_sp 'TT', 'Turno tarde'
EXEC Empresa.InsertarEmpleado_sp 255, 'Jorge', 'Dominguez','M','20-38754165-5', '1142157484', 'Alsina 2354, Ramos Mejia', '12/03/2025', 'jorgeDom@gmail.com', 'jorgeDom@auroraSA.com.ar', 'Cajero', 'RM1', 'TM'    
EXEC Empresa.InsertarEmpleado_sp 310, 'Maria', 'Benitez', 'F', '20-38745411-2', '1146988556', 'Colon 25423, Ramos Mejia', NULL, 'MBenitez@gmail.com', 'MBenitez@auROraSa.com.ar', 'Cajero', 'RM2', 'TT'
-- Inserciones necesarias para la factura

EXEC Ventas.InsertarFactura_sp '754-25-8754', 'A', NULL, 'Efectivo', NULL, '39425412', 255, 'RM1'
EXEC Ventas.InsertarFactura_sp '914-95-2484', 'A', NULL, 'Débito', '4521-4578-8652-4875', '38741442', 310, 'RM1'
SELECT * FROM Ventas.Factura
-- Inserciones normales

EXEC Ventas.InsertarFactura_sp '1234-2484', 'A', NULL, 'Débito', '4521-4578-8652-4875', '38741442', 310, 'RM1'
-- Error: Formato de código inválido

EXEC Ventas.InsertarFactura_sp '314-95-2484', 'Tipo A', NULL, 'Débito', '4521-4578-8652-4875', '38741442', 310, 'RM1'
-- Error: Tipo de factura inexistente (Idem MedioPago, Cliente, Sucursal y Empleado)

EXEC Ventas.ActualizarFactura_sp @codigoFactura = '754-25-8754', @tipoFactura = 'B'
SELECT * FROM Ventas.Factura
-- Actualización de tipo de factura 

EXEC Ventas.EliminarFactura_sp '754-25-8754' 
SELECT * FROM Ventas.Factura
-- Borrado lógico

EXEC Ventas.ReactivarFactura_sp '754-25-8754' 
SELECT * FROM Ventas.Factura
-- Reactivación


CLOSE SYMMETRIC KEY LlaveSimetrica;
-- Cerrar llave de cifrado.

----------------------------------------------------------------------------------------------------------------
-- DetalleFactura

EXEC Inventario.InsertarLineaProducto_sp 'Almacen'
EXEC Inventario.InsertarLineaProducto_sp 'Frutas' 
EXEC Inventario.InsertarProducto_sp 'Aceite de oliva 500ml', 150.2, 'Almacen'
EXEC Inventario.InsertarProducto_sp 'Sal de mesa 250gr', 15.2, 'Almacen'
EXEC Inventario.InsertarProducto_sp 'Manzana', 17.2, 'Frutas'
EXEC Inventario.InsertarProducto_sp 'Naranja', 16.7, 'Frutas'
-- Inseciones necesarias

EXEC Ventas.InsertarDetalleFactura_sp '754-25-8754', 'Aceite de oliva 500ml', 2
EXEC Ventas.InsertarDetalleFactura_sp '754-25-8754', 'Manzana', 5
EXEC Ventas.InsertarDetalleFactura_sp '754-25-8754', 'Naranja', 6
EXEC Ventas.InsertarDetalleFactura_sp '914-95-2484', 'Sal de mesa 250gr', 1
EXEC Ventas.InsertarDetalleFactura_sp '914-95-2484', 'Manzana', 8
SELECT * FROM Ventas.DetalleFactura
-- Inserciones normales

SELECT F.codigoFactura, D.idDetalleFactura item, P.nombreProducto, D.cantidad, D.precioUnitario, D.subtotal, F.total 
FROM Ventas.DetalleFactura D JOIN Ventas.Factura F ON D.idFactura = F.idFactura JOIN Inventario.Producto P ON P.idProducto = D.idProducto
ORDER BY codigoFactura, idDetalleFactura ASC
-- Para mayor facilidad de lectura

SELECT codigoFactura, total FROM Ventas.Factura
-- Se actualiza el total de la factura


EXEC Ventas.InsertarDetalleFactura_sp '754-25-8754', 'Pan frances', 2
-- Error: Producto inexistente (Idem factura)

EXEC Ventas.InsertarDetalleFactura_sp '754-25-8754', 'Manzana', -8
-- Error: Cantidad inválida


EXEC Ventas.ActualizarDetalleFactura_sp @codigoFactura = '754-25-8754', @numDetalle = 1, @cantidad = 3
SELECT F.codigoFactura, D.idDetalleFactura item, P.nombreProducto, D.cantidad, D.precioUnitario, D.subtotal, F.total 
FROM Ventas.DetalleFactura D JOIN Ventas.Factura F ON D.idFactura = F.idFactura JOIN Inventario.Producto P ON P.idProducto = D.idProducto
ORDER BY codigoFactura, idDetalleFactura ASC
-- Actualización de cantidad en item 1 de la factura '754-25-8754'

EXEC Ventas.ActualizarDetalleFactura_sp @codigoFactura = '754-25-8754', @numDetalle = 2, @producto = 'Sal de mesa 250gr'
SELECT F.codigoFactura, D.idDetalleFactura item, P.nombreProducto, D.cantidad, D.precioUnitario, D.subtotal, F.total 
FROM Ventas.DetalleFactura D JOIN Ventas.Factura F ON D.idFactura = F.idFactura JOIN Inventario.Producto P ON P.idProducto = D.idProducto
ORDER BY codigoFactura, idDetalleFactura ASC
-- Actualización de item 2, se cambia el producto (se toma el precio actual del mismo)


EXEC Ventas.ActualizarDetalleFactura_sp @codigoFactura = '754-25-8754', @numDetalle = 2, @producto = 'Naranja'
-- Error: Ya existe un item de factura con el producto

EXEC Ventas.EliminarDetalleFactura_sp '754-25-8754', 3
SELECT F.codigoFactura, D.idDetalleFactura item, P.nombreProducto, D.cantidad, D.precioUnitario, D.subtotal, F.total 
FROM Ventas.DetalleFactura D JOIN Ventas.Factura F ON D.idFactura = F.idFactura JOIN Inventario.Producto P ON P.idProducto = D.idProducto
ORDER BY codigoFactura, idDetalleFactura ASC
-- Se elimina el item 3 de la factura indicada.


----------------------------------------------------------------------------------------------------------------
-- NotaCredito

EXEC Ventas.InsertarNotaCredito_sp 'NC-2023-015489','754-25-8754','39425412',255,NULL,'Devolución de compra'
EXEC Ventas.InsertarNotaCredito_sp 'NC-2023-023563','914-95-2484','38741442',310,NULL,'Devolución de compra'
EXEC Ventas.InsertarNotaCredito_sp 'NC-2023-123563','914-95-2484','38741442',310,NULL,'Segunda devolución'
SELECT * FROM Ventas.NotaCredito
-- Se insertan dos notas de crédito


EXEC Ventas.InsertarNotaCredito_sp 'NC-2023-011489','954-25-8754','39425412',255,NULL,'Devolución de compra'
-- Error: Factura inexistente (Idem cliente, empleado)

EXEC Ventas.InsertarNotaCredito_sp 'NC-2023-035489','754-25-8754','38741442',255,NULL,'Devolución de compra'
-- Error: El cliente no concuerda con la factura

EXEC Ventas.InsertarNotaCredito_sp 'NC-2023-035489','754-25-8754','39425412',255,NULL,''
-- Error: Detalle vacío


EXEC Ventas.ActualizarNotaCredito_sp @codigoNota = 'NC-2023-023563', @detalles = 'Producto defectuoso' 
SELECT * FROM Ventas.NotaCredito
-- Se actualiza el detalle

EXEC Ventas.EliminarNotaCredito_sp 'NC-2023-023563'
SELECT * FROM Ventas.NotaCredito
-- Borrado lógico

EXEC Ventas.ReactivarNotaCredito_sp 'NC-2023-023563'
SELECT * FROM Ventas.NotaCredito
-- Reactivación


EXEC Utilidades.ResetearTablas_sp 
-- Borrar tablas y reiniciar identitys.


----------------------------------------------------------------------------------------------------------------
-- DetalleNota

EXEC Ventas.InsertarDetalleNota_sp 'NC-2023-015489', 'Sal de mesa 250gr', 2
EXEC Ventas.InsertarDetalleNota_sp 'NC-2023-015489', 'Aceite de oliva 500ml', 1
EXEC Ventas.InsertarDetalleNota_sp 'NC-2023-023563', 'Manzana', 5
-- Inserciones de 3 detalles

SELECT * FROM Ventas.DetalleNota

SELECT N.codigoNota, idDetalleNota item, nombreProducto, cantidad, D.precioUnitario, subtotal
FROM Ventas.DetalleNota D JOIN Ventas.NotaCredito N ON N.idNota = D.idNota JOIN Inventario.Producto P ON P.idProducto = D.idProducto
ORDER BY codigoNota, item ASC
-- Se observan las notas de crédito y sus detalles.

EXEC Ventas.InsertarDetalleNota_sp 'NC-2023-015489', 'Mesa', 2
-- Error: Producto inexistente (Idem codigoNota)

EXEC Ventas.InsertarDetalleNota_sp 'NC-2023-015489', 'Naranja', 2
-- Error: El producto no forma parte de la factura

EXEC Ventas.InsertarDetalleNota_sp 'NC-2023-015489', 'Sal de mesa 250gr', 10
-- Error: Ya existe un detalle con este producto

EXEC Ventas.InsertarDetalleNota_sp 'NC-2023-023563', 'Sal de mesa 250gr', 10
-- Error: La cantidad ingresada excede a la facturada

EXEC Ventas.InsertarDetalleNota_sp 'NC-2023-123563', 'Manzana', 4
-- Se crea inserta un detalle en otra nota de crédito de la misma factura
-- Error: La cantidad total registrada en notas de crédito supera a la facturada

SELECT * FROM Ventas.NotaCredito
-- Ver montos actualizados en las notas de crédito

EXEC Ventas.ActualizarDetalleNota_sp @codigoNota = 'NC-2023-015489', @numDetalle = 1, @cantidad = 3
SELECT N.codigoNota, idDetalleNota item, nombreProducto, cantidad, D.precioUnitario, subtotal
FROM Ventas.DetalleNota D JOIN Ventas.NotaCredito N ON N.idNota = D.idNota JOIN Inventario.Producto P ON P.idProducto = D.idProducto
ORDER BY codigoNota, item ASC
-- Actualización de cantidad

SELECT * FROM Ventas.NotaCredito
-- Ver montos nuevamente actualizados en las notas de crédito

EXEC Ventas.ActualizarDetalleNota_sp @codigoNota = 'NC-2023-015489', @numDetalle = 1, @cantidad = 10
-- Error: Cantidad excedida

EXEC Ventas.ActualizarDetalleNota_sp @codigoNota = 'NC-2023-015489', @numDetalle = 1, @producto = 'Aceite de oliva 500ml'
-- Error: Ya existe un detalle con el producto

EXEC Ventas.ActualizarDetalleNota_sp @codigoNota = 'NC-2023-123563', @numDetalle = 1, @producto = 'Naranjas'
-- Error: Detalle inexistente


EXEC Ventas.EliminarDetalleNota_sp 'NC-2023-015489',1
SELECT N.codigoNota, idDetalleNota item, nombreProducto, cantidad, D.precioUnitario, subtotal
FROM Ventas.DetalleNota D JOIN Ventas.NotaCredito N ON N.idNota = D.idNota JOIN Inventario.Producto P ON P.idProducto = D.idProducto
ORDER BY codigoNota, item ASC
-- Borrado del detalle

SELECT * FROM Ventas.NotaCredito
-- Montos actualizados


----------------------------------------------------------------------------------------------------------------
EXEC Utilidades.ResetearTablas_sp 
-- Borrar tablas y reiniciar identitys.
----------------------------------------------------------------------------------------------------------------