/*
Aurora SA
Script de creacion de base de datos, esquemas y encriptación.
GRodriguezAR
*/

------------CREACION DE DATABASE----------
USE master
GO

IF NOT EXISTS (SELECT NAME FROM master.dbo.sysdatabases WHERE NAME = 'AuroraSA_DB')
    CREATE DATABASE AuroraSA-DB COLLATE Modern_Spanish_CS_AS
ELSE
	print 'La base de datos ya existe.'
GO

USE AuroraSA_DB
GO

------------CREACION DE ESQUEMAS----------
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name ='Empresa')
    EXEC('CREATE SCHEMA Empresa')
ELSE
    print 'El esquema Empresa ya existe en la base de datos.'
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Ventas')
    EXEC('CREATE SCHEMA Ventas')
ELSE
    print 'El esquema Ventas ya existe en la base de datos.'
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name ='Inventario')
    EXEC('CREATE SCHEMA Inventario')
ELSE 
    print 'El esquema Inventario ya existe en la base de datos.'
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name ='Utilidades')
    EXEC('CREATE SCHEMA Utilidades')
ELSE 
    print 'El esquema Utilidades ya existe en la base de datos.'
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name ='Reportes')
    EXEC('CREATE SCHEMA Reportes')
ELSE
    print 'El esquema Reportes ya existe en la base de datos.'
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name ='Seguridad')
    EXEC('CREATE SCHEMA Seguridad')
ELSE
    print 'El esquema Seguridad ya existe en la base de datos.'
GO

---------- Encriptación ----------
BEGIN TRY
    -- Llave Maestra con validación
    IF NOT EXISTS ( SELECT 1 FROM sys.symmetric_keys  WHERE name = '##MS_DatabaseMasterKey##')
        CREATE MASTER KEY ENCRYPTION BY PASSWORD = '/*¡ReemplazarPorContraseñaSegura!*/';

    -- Certificado con respaldo automático
    IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = 'CertificadoSeguridad')
    BEGIN
        CREATE CERTIFICATE CertificadoSeguridad
        WITH SUBJECT = 'Cifrado de datos sensibles',
        EXPIRY_DATE = '31/12/2099'; 
        
        -- Respaldar certificado inmediatamente
        BACKUP CERTIFICATE CertificadoSeguridad
        TO FILE = 'E:\CertificadoSeguridad.cer'
        WITH PRIVATE KEY (
            FILE = 'E:\CertificadoSeguridad.pvk',
            ENCRYPTION BY PASSWORD = '/*¡ContraseñaDiferenteALaMaestra!*/'
        );
    END

    -- Llave Simétrica
    IF NOT EXISTS ( SELECT 1 FROM sys.symmetric_keys WHERE name = 'LlaveSimetrica' )
    BEGIN
        CREATE SYMMETRIC KEY LlaveSimetrica
        WITH ALGORITHM = AES_256,
        KEY_SOURCE = '/*¡FuenteSecreta!*/', 
        IDENTITY_VALUE = '/*¡ValorIdentidadUnico!*/'
        ENCRYPTION BY CERTIFICATE CertificadoSeguridad;
    END;

    -- Configurar permisos mínimos necesarios
    --GRANT VIEW DEFINITION ON CERTIFICATE::CertificadoSeguridad TO [RolSeguridad];
    --GRANT CONTROL ON SYMMETRIC KEY::LlaveSimetrica TO [RolSeguridad];
    DENY VIEW DEFINITION ON CERTIFICATE::CertificadoSeguridad TO PUBLIC;
END TRY
BEGIN CATCH
    SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_STATE() AS ErrorState,
        ERROR_PROCEDURE() AS ErrorProcedure,
        ERROR_LINE() AS ErrorLine,
        ERROR_MESSAGE() AS ErrorMessage;
    THROW; 
END CATCH;