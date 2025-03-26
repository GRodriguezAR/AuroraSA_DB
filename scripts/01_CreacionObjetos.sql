/*
Aurora SA
Script de creacion de esquemas, tablas e índices.
GRodriguezAR
*/

-----------CREACION DE ESQUEMAS------------
CREATE SCHEMA Empresa;
GO
CREATE SCHEMA Ventas;
GO
CREATE SCHEMA Inventario;
GO
CREATE SCHEMA Utilidades;
GO
CREATE SCHEMA Reportes;
GO
CREATE SCHEMA Seguridad;
GO


-----------CREACION DE TABLAS------------
-- Empresa.Sucursal
CREATE TABLE Empresa.Sucursal
(
    idSucursal INT IDENTITY(1,1),
    codigoSucursal CHAR(3) NOT NULL,
    direccion NVARCHAR(100) NOT NULL,
    ciudad VARCHAR(50) NOT NULL,
    telefono CHAR(10) NOT NULL,
    horario VARCHAR(55) NOT NULL,
    activo BIT DEFAULT 1 NOT NULL ,
    CONSTRAINT PK_Sucursal PRIMARY KEY (idSucursal),
    CONSTRAINT UQ_Sucursal_codigo UNIQUE (codigoSucursal),
    CONSTRAINT CHK_Sucursal_codigo CHECK (codigoSucursal LIKE '[A-Z][A-Z][0-9]'),
    CONSTRAINT CHK_Sucursal_telefono CHECK (telefono LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]'),
    CONSTRAINT CHK_Sucursal_direccion CHECK (LEN(LTRIM(RTRIM(direccion))) > 0),
    CONSTRAINT CHK_Sucursal_ciudad CHECK (LEN(LTRIM(RTRIM(ciudad))) > 0),
    CONSTRAINT CHK_Sucursal_horario CHECK (LEN(LTRIM(RTRIM(horario))) > 0)
);
GO
-- Empresa.Cargo
CREATE TABLE Empresa.Cargo
(
    idCargo INT IDENTITY(1,1),
    nombre VARCHAR(20) NOT NULL,
    descripcion NVARCHAR(100) NOT NULL,
    activo BIT DEFAULT 1 NOT NULL ,
    CONSTRAINT PK_Cargo PRIMARY KEY (idCargo),
    CONSTRAINT UQ_Cargo_nombre UNIQUE (nombre),
    CONSTRAINT CHK_Cargo_nombre CHECK (LEN(LTRIM(RTRIM(nombre))) > 0),
    CONSTRAINT CHK_Cargo_descripcion CHECK (LEN(LTRIM(RTRIM(descripcion))) > 0)
);
GO
-- Empresa.Turno
CREATE TABLE Empresa.Turno
(
    idTurno INT IDENTITY(1,1),
    acronimo CHAR(2) NOT NULL,
    descripcion NVARCHAR(25) NOT NULL,
    activo BIT DEFAULT 1 NOT NULL ,
    CONSTRAINT PK_Turno PRIMARY KEY (idTurno),
    CONSTRAINT UQ_Turno_acronimo UNIQUE (acronimo),
    CONSTRAINT CHK_Turno_acronimo CHECK (acronimo LIKE '[A-Z][A-Z]'),
    CONSTRAINT CHK_Turno_descripcion CHECK (LEN(LTRIM(RTRIM(descripcion))) > 0)
);
GO

-- Empresa.Empleado
CREATE TABLE Empresa.Empleado
(
    idEmpleado INT IDENTITY,
    legajo INT NOT NULL,
    nombre VARCHAR(30) NOT NULL,
    apellido VARCHAR(30) NOT NULL,
    genero CHAR(1) NOT NULL,
    cuil VARBINARY(256) NOT NULL,
    cuilHASH VARBINARY(64) NOT NULL,
    telefono VARBINARY(256) NOT NULL,
    domicilio VARBINARY(256) NOT NULL,
    fechaAlta DATE NOT NULL DEFAULT GETDATE(),
    mailPersonal VARBINARY(256) NOT NULL,
    mailEmpresa VARCHAR(55) NOT NULL,
    idCargo INT,
    idSucursal INT,
    idTurno INT,
    activo BIT DEFAULT 1 NOT NULL,
    CONSTRAINT PK_Empleado PRIMARY KEY (idEmpleado),
    CONSTRAINT FK_Empleado_Sucursal FOREIGN KEY (idSucursal) REFERENCES Empresa.Sucursal(idSucursal),
    CONSTRAINT FK_Empleado_Cargo FOREIGN KEY (idCargo) REFERENCES Empresa.Cargo(idCargo),
    CONSTRAINT FK_Empleado_Turno FOREIGN KEY (idTurno) REFERENCES Empresa.Turno(idTurno),
	CONSTRAINT UQ_Empleado_legajo UNIQUE (legajo),
    CONSTRAINT CHK_Empleado_legajo CHECK (LEN(LTRIM(RTRIM(legajo))) > 0),
    CONSTRAINT CHK_Empleado_genero CHECK (genero IN ('M', 'F')),
    CONSTRAINT CHK_Empleado_mailEmpresa CHECK (LOWER(mailEmpresa) LIKE '_%@aurorasa.com.ar')
);
GO

-- Inventario.LineaProducto
CREATE TABLE Inventario.LineaProducto
(
	idLineaProd INT IDENTITY(1,1),
	descripcion VARCHAR(30) NOT NULL,
	activo BIT DEFAULT 1 NOT NULL,
	CONSTRAINT PK_LineaProducto PRIMARY KEY (idLineaProd),
    CONSTRAINT UQ_LineaProducto_descripcion UNIQUE (descripcion),
    CONSTRAINT CHK_Turno_descripcion CHECK (LEN(LTRIM(RTRIM(descripcion))) > 0)
);
GO

-- Inventario.Producto
CREATE TABLE Inventario.Producto
(
    idProducto INT IDENTITY(1,1),
    r NVARCHAR(100) COLLATE Modern_Spanish_CI_AI NOT NULL,
    precioUnitario DECIMAL(10,2) NOT NULL,
    idLineaProducto INT NOT NULL,
    activo BIT DEFAULT 1 NOT NULL,   
    CONSTRAINT PK_Producto PRIMARY KEY (idProducto),
	CONSTRAINT FK_Producto_idLineaProducto FOREIGN KEY (idLineaProducto) REFERENCES Inventario.LineaProducto(idLineaProd),
    CONSTRAINT UQ_Producto_nombreProducto UNIQUE (nombreProducto),
    CONSTRAINT CHK_Producto_precioUnitario CHECK (precioUnitario > 0),
    CONSTRAINT CHK_Producto_nombreProducto CHECK (LEN(LTRIM(RTRIM(nombreProducto))) > 0)
);
GO

-- Ventas.Cliente
CREATE TABLE Ventas.Cliente
(
    idCliente INT IDENTITY(1,1),
    nombre VARCHAR(30) NOT NULL,
    apellido VARCHAR(30) NOT NULL,
    dni VARBINARY(256) NOT NULL,
    dniHASH VARBINARY(32),
    genero CHAR(1) NOT NULL,
    tipoCliente VARCHAR(10) DEFAULT 'Normal' NOT NULL,
    puntos INT DEFAULT NULL,
    fechaAlta DATETIME DEFAULT GETDATE() NOT NULL,
    activo BIT DEFAULT 1 NOT NULL,
    CONSTRAINT PK_Cliente PRIMARY KEY (idCliente),
    CONSTRAINT CHK_Cliente_genero CHECK (genero IN ('M', 'F')),
    CONSTRAINT CHK_Cliente_tipoCliente CHECK (tipoCliente IN ('Normal', 'Miembro')),
    CONSTRAINT CHK_Cliente_nombre CHECK (LEN(LTRIM(RTRIM(nombre))) > 0),
    CONSTRAINT CHK_Cliente_apellido CHECK (LEN(LTRIM(RTRIM(apellido))) > 0)
);
GO

-- Ventas.MedioPago
CREATE TABLE Ventas.MedioPago
(
    idMedio INT IDENTITY(1,1),
    nombre NVARCHAR(30) NOT NULL,
    activo BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_MedioPago PRIMARY KEY (idMedio),
    CONSTRAINT UQ_MedioPago_nombre UNIQUE (nombre),
    CONSTRAINT CHK_MedioPago_nombre CHECK (LEN(LTRIM(RTRIM(nombre))) > 0)
);
GO

-- Ventas.Factura
CREATE TABLE Ventas.Factura
(
    idFactura INT IDENTITY(1,1) NOT NULL, 
    codigoFactura CHAR(11) NOT NULL,
    tipoFactura CHAR(1) NOT NULL,
    fecha DATETIME DEFAULT GETDATE() NOT NULL,
    detallesPago VARCHAR(100) DEFAULT NULL,
    total DECIMAL(10,2) DEFAULT 0 NOT NULL,
    idMedioPago INT,
    idCliente INT,
    idEmpleado INT,
    idSucursal INT,
    activo BIT DEFAULT 1 NOT NULL,      
    CONSTRAINT PK_Factura PRIMARY KEY (idFactura),
    CONSTRAINT FK_Factura_MedioPago FOREIGN KEY (idMedioPago) REFERENCES Ventas.MedioPago (idMedio),
    CONSTRAINT FK_Factura_Cliente FOREIGN KEY (idCliente) REFERENCES Ventas.Cliente (idCliente),
    CONSTRAINT FK_Factura_Empleado FOREIGN KEY (idEmpleado) REFERENCES Empresa.Empleado (idEmpleado),
    CONSTRAINT FK_Factura_Sucursal FOREIGN KEY (idSucursal) REFERENCES Empresa.Sucursal(idSucursal),
    CONSTRAINT UQ_Factura_codigoFactura UNIQUE (codigoFactura),
    CONSTRAINT CHK_Factura_codigoFactura CHECK (codigoFactura LIKE '[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]'),
    CONSTRAINT CHK_Factura_tipoFactura CHECK (tipoFactura in ('A','B','C')),
    CONSTRAINT CHK_Factura_total CHECK (total >= 0)
);
GO

-- Ventas.DetalleFactura
CREATE TABLE Ventas.DetalleFactura
(
    idFactura INT,
    idDetalleFactura INT,
    idProducto INT,
    cantidad INT NOT NULL,
    precioUnitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_DetalleVenta PRIMARY KEY (idDetalleFactura,idFactura),
    CONSTRAINT FK_DetalleFactura_Factura FOREIGN KEY (idFactura) REFERENCES Ventas.Factura(idFactura),
    CONSTRAINT FK_DetalleFactura_Producto FOREIGN KEY (idProducto) REFERENCES Inventario.Producto (idProducto),
    CONSTRAINT CHK_DetalleFactura_cantidad CHECK (cantidad > 0),
    CONSTRAINT CHK_DetalleVenta_subtotal CHECK (subtotal > 0),
    CONSTRAINT CHK_DetalleVenta_precioUnitario CHECK (precioUnitario > 0)
);
GO

-- Ventas.NotaCredito
CREATE TABLE Ventas.NotaCredito
(
	idNota INT IDENTITY (1,1),
	codigoNota CHAR(14) NOT NULL,
    idFactura  INT,
	idCliente INT,
    idEmpleado INT,
	monto DECIMAL(10,2) DEFAULT 0 NOT NULL,
	fecha DATE DEFAULT GETDATE() NOT NULL,
	detalles NVARCHAR(200) NOT NULL,
    activo BIT DEFAULT 1 NOT NULL,   
	CONSTRAINT PK_NotaCredito PRIMARY KEY (idNota), 
	CONSTRAINT FK_NotaCredito_Cliente FOREIGN KEY (idCliente) REFERENCES Ventas.Cliente(idCliente),
	CONSTRAINT FK_NotaCredito_Factura FOREIGN KEY (idFactura) REFERENCES Ventas.Factura(idFactura),
	CONSTRAINT FK_NotaCredito_Empleado FOREIGN KEY (idEmpleado) REFERENCES Empresa.Empleado(idEmpleado),
    CONSTRAINT CHK_NotaCredito_codigoNota CHECK (codigoNota LIKE 'NC-2[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]'),
    CONSTRAINT UQ_NotaCredito_codigoNota UNIQUE (codigoNota),
    CONSTRAINT CHK_NotaCredito_monto CHECK (monto >= 0),
    CONSTRAINT CHK_NotaCredito_detalles CHECK (LEN(LTRIM(RTRIM(detalles))) > 0)
 );
 GO

 -- Ventas.DetalleNota
CREATE TABLE Ventas.DetalleNota
(
    idNota INT,
    idDetalleNota INT,
    idProducto INT,
    cantidad INT NOT NULL,
    precioUnitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_DetalleNota PRIMARY KEY (idDetalleNota,idNota),
    CONSTRAINT FK_DetalleNota_NotaCredito FOREIGN KEY (idNota) REFERENCES Ventas.NotaCredito(idNota),
    CONSTRAINT FK_DetalleNota_Producto FOREIGN KEY (idProducto) REFERENCES Inventario.Producto(idProducto),
    CONSTRAINT CHK_DetalleNota_cantidad CHECK (cantidad > 0),
    CONSTRAINT CHK_DetalleNota_subtotal CHECK (subtotal > 0),
    CONSTRAINT CHK_DetalleNota_precioUnitario CHECK (precioUnitario > 0)
);
GO


-------------------------- CREACION DE INDICES --------------------------

-- Indice codigo de Sucursal
    CREATE UNIQUE NONCLUSTERED INDEX ix_codSucursal_Sucursal ON Empresa.Sucursal(codigoSucursal)
    GO
-- Indice acronimo de Turno
    CREATE UNIQUE NONCLUSTERED INDEX ix_acronimo_Turno ON Empresa.Turno(acronimo)
    GO
-- Indice nombre de Cargo
    CREATE UNIQUE NONCLUSTERED INDEX ix_nombre_Cargo ON Empresa.Cargo(nombre)
    GO
-- Indice legajo de Empleado
    CREATE UNIQUE NONCLUSTERED INDEX ix_legajo_Empleado ON Empresa.Empleado(legajo)
    GO
-- Indice cuilHASH de Empleado
    CREATE UNIQUE NONCLUSTERED INDEX ix_cuilHASH_Empleado ON Empresa.Empleado (cuilHASH) WITH (DATA_COMPRESSION = PAGE); 
    GO
-- Indice descripcion de LineaProducto
    CREATE UNIQUE NONCLUSTERED INDEX ix_descripcion_LineaProducto ON Inventario.LineaProducto(descripcion)
    GO
-- Indice nombreProducto de Prodcuto
    CREATE UNIQUE NONCLUSTERED INDEX ix_nombreProd_Producto ON Inventario.Producto(nombreProducto)
    GO
-- Indice idLineaProducto de Prodcuto
    CREATE NONCLUSTERED INDEX ix_idLineaProducto_Producto ON Inventario.Producto(idLineaProducto)
    GO
-- Indice dniHASH de Empleado
    CREATE UNIQUE NONCLUSTERED INDEX ix_dniHASH_Cliente ON Ventas.Cliente (dniHASH)
    GO
-- Indice nombre de MedioPago
    CREATE NONCLUSTERED INDEX ix_nombre_MedioPago ON Ventas.MedioPago(nombre)
    GO
-- Indice codigoFactura en Factura
    CREATE NONCLUSTERED INDEX ix_codFactura_Factura ON Ventas.Factura(codigoFactura)
    GO
-- Indice codigoNota en NotaCredito
    CREATE NONCLUSTERED INDEX ix_codigoNota_NotaCredito ON Ventas.NotaCredito(codigoNota)
    GO

--IF NOT EXISTS 
--	(SELECT 1 FROM sys.indexes
--    WHERE name = 'ix_fechaFact' AND object_id = OBJECT_ID('Ventas.Factura')
--)
--    CREATE INDEX ix_fechaFact ON Ventas.Factura(fecha);


--IF NOT EXISTS (
--	SELECT 1 FROM sys.indexes
--    WHERE name = 'ix_sucFact' AND object_id = OBJECT_ID('Ventas.Factura')
--)
--    CREATE INDEX ix_sucFact ON Ventas.Factura(idSucursal);

