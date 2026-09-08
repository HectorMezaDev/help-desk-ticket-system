USE MesaAyudaDb;
GO

SELECT DB_NAME() AS BaseActual, @@SERVERNAME AS Servidor;

SELECT
    (SELECT COUNT(*) FROM dbo.Roles) AS Roles,
    (SELECT COUNT(*) FROM dbo.Usuarios) AS Usuarios,
    (SELECT COUNT(*) FROM dbo.Departamentos) AS Departamentos,
    (SELECT COUNT(*) FROM dbo.Categorias) AS Categorias,
    (SELECT COUNT(*) FROM dbo.Prioridades) AS Prioridades,
    (SELECT COUNT(*) FROM dbo.Estados) AS Estados,
    (SELECT COUNT(*) FROM sys.procedures WHERE schema_id = SCHEMA_ID(N'dbo') AND name LIKE N'sp_%') AS Procedimientos,
    (SELECT COUNT(*) FROM sys.triggers WHERE name = N'tr_Tickets_Auditoria') AS TriggersAuditoria;

EXEC dbo.sp_UsuarioAutenticar
    @Correo = N'admin@mesaayuda.local',
    @PasswordHash = '0a5bc3e342432f1bad92ffd51b785343ec72906cdba6a26131060b008e786656';
GO
