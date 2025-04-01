/*
Aurora SA
Tests de procedimientos ABM de esquema Empresa
GRodriguezAR
*/

Use [AuroraSA_DB]
GO

----------------------------------------------------------------------------------------------------------------
-- Sucursal

EXEC Empresa.InsertarSucursal_sp 'RM1', 'Av. Rivadavia 12324', 'Ramos Mejia', '4075-8745','L a V 09 a 20'
EXEC Empresa.InsertarSucursal_sp 'RM2', 'Av. de Mayo 654', 'Ramos Mejia', '4123-5634','L a V 09 a 20'
SELECT * FROM Empresa.Sucursal
-- Inserciones normales

EXEC Empresa.InsertarSucursal_sp 'RM1', 'Av. Rivadavia 12324', 'Ramos Mejia', '4075-8745','L a V 09 a 20'
-- Error: Codigo repetido

EXEC Empresa.InsertarSucursal_sp 'RAMOS 1', 'Av. Rivadavia 12324', 'Ramos Mejia', '4075-8745','L a V 09 a 20'
-- Error: Código inválido

EXEC Empresa.InsertarSucursal_sp 'RM2', '', 'Ramos Mejia', '4075-8745','L a V 09 a 20'
-- Error: Campos vacios

EXEC Empresa.InsertarSucursal_sp 'RM2', 'Av. Rivadavia 12324', 'Ramos Mejia', '12345','L a V 09 a 20'
-- Error: Telefono inválido

EXEC Empresa.ActualizarSucursal_sp @codigoSucursal = 'RM1', @direccion = 'Pueyrredon 2324'
SELECT * FROM Empresa.Sucursal
-- Actualización de domicilio

EXEC Empresa.ActualizarSucursal_sp @codigoSucursal = 'RM1'
-- Error: No se indico ninguna actualización

EXEC Empresa.ActualizarSucursal_sp @codigoSucursal = 'RM5', @nuevoCodigo = 'RM2'
-- Error: La sucursal no existe

EXEC Empresa.ActualizarSucursal_sp @codigoSucursal = 'RM1', @nuevoCodigo = 'RM2'
-- Error: Ya existe una sucursal con el nuevo código

EXEC Empresa.EliminarSucursal_sp 'RM1'
SELECT * FROM Empresa.Sucursal
-- Borrado lógico

EXEC Empresa.EliminarSucursal_sp 'RM1'
-- Error: Ya se encuentra inactiva

EXEC Empresa.ReactivarSucursal_sp 'RM1'
SELECT * FROM Empresa.Sucursal
-- Reactivación


----------------------------------------------------------------------------------------------------------------
-- CARGO
EXEC Empresa.InsertarCargo_sp 'Cajero', 'Cajero de mostrador'
EXEC Empresa.InsertarCargo_sp 'Supervisor', 'Jefe de cajeros'
SELECT * FROM Empresa.Cargo
-- Inserciones normales

EXEC Empresa.InsertarCargo_sp 'Cajero', 'Caja'
-- Error: Cargo ya existente

EXEC Empresa.InsertarCargo_sp 'Asistente', ''
-- Error: Descripción vacía

EXEC Empresa.ActualizarCargo_sp 'Cajero', 'Encargado de ventas'
SELECT * FROM Empresa.Cargo
-- Actualización de descripción

EXEC Empresa.ActualizarCargo_sp 'Gerente', 'Jefe de sucursal'
-- Error: El cargo no existe

EXEC Empresa.EliminarCargo_sp 'Supervisor'
SELECT * FROM Empresa.Cargo
-- Borrado lógico

EXEC Empresa.ReactivarCargo_sp 'Supervisor'
SELECT * FROM Empresa.Cargo
-- Reactivación

----------------------------------------------------------------------------------------------------------------
-- TURNO

EXEC Empresa.InsertarTurno_sp 'TM', 'Turno mañana'
EXEC Empresa.InsertarTurno_sp 'TT', 'Turno tarde'
SELECT * FROM Empresa.Turno
-- Inserciones normales

EXEC Empresa.InsertarTurno_sp 'Turno noche', 'horario nocturno'
-- Error: Formato de turno inválido

EXEC Empresa.InsertarCargo_sp 'TN', ''
-- Error: Descripción vacía

EXEC Empresa.ActualizarTurno_sp 'TM', 'De 09 a 13'
SELECT * FROM Empresa.Turno
-- Actualización de descripción

EXEC Empresa.ActualizarTurno_sp 'TN', 'Turno noche'
-- Error: El turno no existe

EXEC Empresa.EliminarTurno_sp 'TM'
SELECT * FROM Empresa.Turno
-- Borrado lógico

EXEC Empresa.ReactivarTurno_sp 'TM'
SELECT * FROM Empresa.Turno
-- Reactivación

----------------------------------------------------------------------------------------------------------------
-- EMPLEADO

OPEN SYMMETRIC KEY LlaveSimetrica DECRYPTION BY CERTIFICATE CertificadoSeguridad;
-- Necesario para insertar campos encriptados

EXEC Empresa.InsertarEmpleado_sp 199,'Jorge','Dominguez','M','20-38754165-5', '1142157484', 'Alsina 2354, Ramos Mejia', '12/03/2025', 'jorgeDom@gmail.com', 'jorgeDom@auroraSA.com.ar', 'Cajero', 'RM1', 'TM'    
EXEC Empresa.InsertarEmpleado_sp 1234, 'Maria', 'Benitez', 'F', '20-38745411-2', '1146988556', 'Colon 25423', NULL, 'MBenitez@gmail.com', 'MBenitez@auROraSa.com.ar', 'Supervisor', 'RM2', 'TT'
SELECT * FROM Empresa.Empleado -- Campos sensibles encripados

SELECT idEmpleado, legajo, nombre, apellido, genero,
    CONVERT(VARCHAR, DECRYPTBYKEY(cuil)) AS cuil,
	CONVERT(VARCHAR, DECRYPTBYKEY(telefono)) AS telefono,
	CONVERT(NVARCHAR, DECRYPTBYKEY(domicilio)) AS domicilio, fechaAlta,
    CONVERT(VARCHAR, DECRYPTBYKEY(mailPersonal)) AS mailPersonal, mailEmpresa, idCargo, idSucursal, idTurno
FROM Empresa.Empleado;
-- Inserciones normales

EXEC Empresa.InsertarEmpleado_sp 199,'Jorge','Dominguez','M','20-38754165-5', '1142157484', 'Alsina 2354, Ramos Mejia', '12/03/2025', 'jorgeDom@gmail.com', 'jorgeDom@auroraSA.com.ar', 'Cajero', 'RM1', 'TM'    
-- Error: Legajo repetido

EXEC Empresa.InsertarEmpleado_sp 200,'Jorge','Dominguez','M','20-38754165-5', '1142157484', 'Alsina 2354, Ramos Mejia', '12/03/2025', 'jorgeDom@gmail.com', 'jorgeDom@auroraSA.com.ar', 'Cajero', 'RM1', 'TM'    
-- Error: Cuil repetido

EXEC Empresa.InsertarEmpleado_sp 200,'Jorge','Dominguez','M','222', '1142157484', 'Alsina 2354, Ramos Mejia', '12/03/2025', 'jorgeDom@gmail.com', 'jorgeDom@auroraSA.com.ar', 'Cajero', 'RM1', 'TM'    
-- Error: Formato de cuil inválido (Idem teléfono, genero, sucursal, turno)

EXEC Empresa.InsertarEmpleado_sp 200,'Jorge','Dominguez','M','20-37754265-5', '1142157484', 'Alsina 2354, Ramos Mejia', '12/03/2025', 'jorgeDom@gmail.com', 'jorgeDom@no.com.ar', 'Cajero', 'RM1', 'TM'    
-- Error: Formato de mail empresa (Idem mail personal)

EXEC Empresa.InsertarEmpleado_sp 300,'Jorge','Dominguez','M','20-36754165-5', '1142157484', 'Alsina 2354, Ramos Mejia', '12/03/2025', 'jorgeDom@gmail.com', 'jorgeDom@auroraSA.com.ar', 'Cajero', 'SJ1', 'TM'    
-- Error: Sucursal inexistente (Idem turno y cargo)

EXEC Empresa.ActualizarEmpleado_sp @legajo = 199, @cargo = 'Supervisor'
SELECT legajo,E.nombre,apellido,C.nombre Cargo FROM Empresa.Empleado E JOIN Empresa.Cargo C ON E.idCargo = C.idCargo
-- Actualización de cargo

EXEC Empresa.ActualizarEmpleado_sp @legajo = 199, @nuevoLegajo = 2124
SELECT legajo, nombre,apellido FROM Empresa.Empleado
-- Actualización de legajo

EXEC Empresa.EliminarEmpleado_sp @legajo = 199
SELECT legajo, activo FROM Empresa.Empleado
-- Borrado lógico

EXEC Empresa.ReactivarEmpleado_sp @legajo = 199
SELECT legajo, activo FROM Empresa.Empleado
-- Reactivación

CLOSE SYMMETRIC KEY LlaveSimetrica;
-- Cerrar llave de cifrado.



----------------------------------------------------------------------------------------------------------------
EXEC Utilidades.ResetearTablas_sp 
-- Borrar tablas y reiniciar identitys.
----------------------------------------------------------------------------------------------------------------