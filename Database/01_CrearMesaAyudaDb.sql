USE master;
GO

IF DB_ID(N'MesaAyudaDb') IS NULL
BEGIN
    CREATE DATABASE MesaAyudaDb;
END;
GO

USE MesaAyudaDb;
GO

IF OBJECT_ID(N'dbo.Roles', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Roles
    (
        RolId       INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Roles PRIMARY KEY,
        Nombre      NVARCHAR(50) NOT NULL CONSTRAINT UQ_Roles_Nombre UNIQUE,
        Activo      BIT NOT NULL CONSTRAINT DF_Roles_Activo DEFAULT (1)
    );
END;
GO

IF OBJECT_ID(N'dbo.Departamentos', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Departamentos
    (
        DepartamentoId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Departamentos PRIMARY KEY,
        Nombre         NVARCHAR(100) NOT NULL CONSTRAINT UQ_Departamentos_Nombre UNIQUE,
        Activo         BIT NOT NULL CONSTRAINT DF_Departamentos_Activo DEFAULT (1)
    );
END;
GO

IF OBJECT_ID(N'dbo.Categorias', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Categorias
    (
        CategoriaId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Categorias PRIMARY KEY,
        Nombre      NVARCHAR(100) NOT NULL CONSTRAINT UQ_Categorias_Nombre UNIQUE,
        Activo      BIT NOT NULL CONSTRAINT DF_Categorias_Activo DEFAULT (1)
    );
END;
GO

IF OBJECT_ID(N'dbo.Prioridades', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Prioridades
    (
        PrioridadId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Prioridades PRIMARY KEY,
        Nombre      NVARCHAR(30) NOT NULL CONSTRAINT UQ_Prioridades_Nombre UNIQUE,
        Nivel       TINYINT NOT NULL CONSTRAINT UQ_Prioridades_Nivel UNIQUE,
        Activo      BIT NOT NULL CONSTRAINT DF_Prioridades_Activo DEFAULT (1)
    );
END;
GO

IF OBJECT_ID(N'dbo.Estados', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Estados
    (
        EstadoId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Estados PRIMARY KEY,
        Nombre   NVARCHAR(50) NOT NULL CONSTRAINT UQ_Estados_Nombre UNIQUE,
        EsFinal  BIT NOT NULL CONSTRAINT DF_Estados_EsFinal DEFAULT (0),
        Activo   BIT NOT NULL CONSTRAINT DF_Estados_Activo DEFAULT (1)
    );
END;
GO

IF OBJECT_ID(N'dbo.Usuarios', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Usuarios
    (
        UsuarioId       INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Usuarios PRIMARY KEY,
        NombreCompleto  NVARCHAR(150) NOT NULL,
        Correo          NVARCHAR(150) NOT NULL CONSTRAINT UQ_Usuarios_Correo UNIQUE,
        PasswordHash    CHAR(64) NOT NULL,
        RolId           INT NOT NULL,
        DepartamentoId  INT NULL,
        Activo          BIT NOT NULL CONSTRAINT DF_Usuarios_Activo DEFAULT (1),
        FechaCreacion   DATETIME2(0) NOT NULL CONSTRAINT DF_Usuarios_Fecha DEFAULT (SYSDATETIME()),
        CONSTRAINT FK_Usuarios_Roles FOREIGN KEY (RolId) REFERENCES dbo.Roles(RolId),
        CONSTRAINT FK_Usuarios_Departamentos FOREIGN KEY (DepartamentoId) REFERENCES dbo.Departamentos(DepartamentoId),
        CONSTRAINT CK_Usuarios_PasswordHash CHECK (LEN(PasswordHash) = 64)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.sequences WHERE object_id = OBJECT_ID(N'dbo.SecuenciaTickets'))
BEGIN
    EXEC(N'CREATE SEQUENCE dbo.SecuenciaTickets AS INT START WITH 1001 INCREMENT BY 1;');
END;
GO

IF OBJECT_ID(N'dbo.Tickets', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Tickets
    (
        TicketId             INT NOT NULL CONSTRAINT DF_Tickets_Id DEFAULT (NEXT VALUE FOR dbo.SecuenciaTickets),
        Numero               VARCHAR(20) NOT NULL,
        UsuarioSolicitanteId INT NOT NULL,
        DepartamentoId       INT NOT NULL,
        CategoriaId          INT NOT NULL,
        PrioridadId          INT NOT NULL,
        Descripcion          NVARCHAR(2000) NOT NULL,
        FechaCreacion        DATETIME2(0) NOT NULL,
        EstadoId             INT NOT NULL,
        TecnicoAsignadoId    INT NULL,
        FechaCierre          DATETIME2(0) NULL,
        HashIntegridad       CHAR(64) NOT NULL,
        CONSTRAINT PK_Tickets PRIMARY KEY (TicketId),
        CONSTRAINT UQ_Tickets_Numero UNIQUE (Numero),
        CONSTRAINT FK_Tickets_Usuarios FOREIGN KEY (UsuarioSolicitanteId) REFERENCES dbo.Usuarios(UsuarioId),
        CONSTRAINT FK_Tickets_Departamentos FOREIGN KEY (DepartamentoId) REFERENCES dbo.Departamentos(DepartamentoId),
        CONSTRAINT FK_Tickets_Categorias FOREIGN KEY (CategoriaId) REFERENCES dbo.Categorias(CategoriaId),
        CONSTRAINT FK_Tickets_Prioridades FOREIGN KEY (PrioridadId) REFERENCES dbo.Prioridades(PrioridadId),
        CONSTRAINT FK_Tickets_Estados FOREIGN KEY (EstadoId) REFERENCES dbo.Estados(EstadoId),
        CONSTRAINT FK_Tickets_Tecnicos FOREIGN KEY (TecnicoAsignadoId) REFERENCES dbo.Usuarios(UsuarioId),
        CONSTRAINT CK_Tickets_Hash CHECK (LEN(HashIntegridad) = 64)
    );
END;
GO

IF OBJECT_ID(N'dbo.Evidencias', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Evidencias
    (
        EvidenciaId    INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Evidencias PRIMARY KEY,
        TicketId       INT NOT NULL,
        NombreOriginal NVARCHAR(255) NOT NULL,
        RutaRelativa   NVARCHAR(500) NOT NULL,
        TipoContenido  NVARCHAR(100) NOT NULL,
        TamanioBytes   BIGINT NOT NULL,
        HashArchivo    CHAR(64) NOT NULL,
        UsuarioId      INT NOT NULL,
        FechaCarga     DATETIME2(0) NOT NULL CONSTRAINT DF_Evidencias_Fecha DEFAULT (SYSDATETIME()),
        CONSTRAINT FK_Evidencias_Tickets FOREIGN KEY (TicketId) REFERENCES dbo.Tickets(TicketId),
        CONSTRAINT FK_Evidencias_Usuarios FOREIGN KEY (UsuarioId) REFERENCES dbo.Usuarios(UsuarioId),
        CONSTRAINT CK_Evidencias_Tamanio CHECK (TamanioBytes > 0 AND TamanioBytes <= 5242880),
        CONSTRAINT CK_Evidencias_Hash CHECK (LEN(HashArchivo) = 64)
    );
END;
GO

IF OBJECT_ID(N'dbo.BitacoraTickets', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.BitacoraTickets
    (
        BitacoraId       BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_BitacoraTickets PRIMARY KEY,
        TicketId         INT NOT NULL,
        UsuarioId        INT NULL,
        Operacion        NVARCHAR(20) NOT NULL,
        Fecha             DATETIME2(0) NOT NULL CONSTRAINT DF_Bitacora_Fecha DEFAULT (SYSDATETIME()),
        Cambios           NVARCHAR(1000) NOT NULL,
        ValoresAnteriores NVARCHAR(MAX) NULL,
        ValoresNuevos     NVARCHAR(MAX) NULL,
        CONSTRAINT FK_Bitacora_Usuarios FOREIGN KEY (UsuarioId) REFERENCES dbo.Usuarios(UsuarioId)
    );

    CREATE INDEX IX_BitacoraTickets_TicketFecha
        ON dbo.BitacoraTickets(TicketId, Fecha DESC);
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE Nombre = N'Administrador') INSERT dbo.Roles(Nombre) VALUES (N'Administrador');
IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE Nombre = N'Tecnico') INSERT dbo.Roles(Nombre) VALUES (N'Tecnico');
IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE Nombre = N'Empleado') INSERT dbo.Roles(Nombre) VALUES (N'Empleado');

IF NOT EXISTS (SELECT 1 FROM dbo.Departamentos WHERE Nombre = N'Sistemas') INSERT dbo.Departamentos(Nombre) VALUES (N'Sistemas');
IF NOT EXISTS (SELECT 1 FROM dbo.Departamentos WHERE Nombre = N'Contabilidad') INSERT dbo.Departamentos(Nombre) VALUES (N'Contabilidad');
IF NOT EXISTS (SELECT 1 FROM dbo.Departamentos WHERE Nombre = N'Operaciones') INSERT dbo.Departamentos(Nombre) VALUES (N'Operaciones');
IF NOT EXISTS (SELECT 1 FROM dbo.Departamentos WHERE Nombre = N'Recursos Humanos') INSERT dbo.Departamentos(Nombre) VALUES (N'Recursos Humanos');

IF NOT EXISTS (SELECT 1 FROM dbo.Categorias WHERE Nombre = N'Falla de Hardware') INSERT dbo.Categorias(Nombre) VALUES (N'Falla de Hardware');
IF NOT EXISTS (SELECT 1 FROM dbo.Categorias WHERE Nombre = N'Error de Software') INSERT dbo.Categorias(Nombre) VALUES (N'Error de Software');
IF NOT EXISTS (SELECT 1 FROM dbo.Categorias WHERE Nombre = N'Problema de Red') INSERT dbo.Categorias(Nombre) VALUES (N'Problema de Red');
IF NOT EXISTS (SELECT 1 FROM dbo.Categorias WHERE Nombre = N'Accesos y Cuentas') INSERT dbo.Categorias(Nombre) VALUES (N'Accesos y Cuentas');

IF NOT EXISTS (SELECT 1 FROM dbo.Prioridades WHERE Nombre = N'Baja') INSERT dbo.Prioridades(Nombre, Nivel) VALUES (N'Baja', 1);
IF NOT EXISTS (SELECT 1 FROM dbo.Prioridades WHERE Nombre = N'Media') INSERT dbo.Prioridades(Nombre, Nivel) VALUES (N'Media', 2);
IF NOT EXISTS (SELECT 1 FROM dbo.Prioridades WHERE Nombre = N'Alta') INSERT dbo.Prioridades(Nombre, Nivel) VALUES (N'Alta', 3);

IF NOT EXISTS (SELECT 1 FROM dbo.Estados WHERE Nombre = N'Abierto') INSERT dbo.Estados(Nombre, EsFinal) VALUES (N'Abierto', 0);
IF NOT EXISTS (SELECT 1 FROM dbo.Estados WHERE Nombre = N'Asignado') INSERT dbo.Estados(Nombre, EsFinal) VALUES (N'Asignado', 0);
IF NOT EXISTS (SELECT 1 FROM dbo.Estados WHERE Nombre = N'En Proceso') INSERT dbo.Estados(Nombre, EsFinal) VALUES (N'En Proceso', 0);
IF NOT EXISTS (SELECT 1 FROM dbo.Estados WHERE Nombre = N'Cerrado') INSERT dbo.Estados(Nombre, EsFinal) VALUES (N'Cerrado', 1);
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios WHERE Correo = N'admin@mesaayuda.local')
BEGIN
    INSERT dbo.Usuarios(NombreCompleto, Correo, PasswordHash, RolId, DepartamentoId)
    SELECT N'David Meza', N'admin@mesaayuda.local',
           LOWER(CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'Admin123*'), 2)),
           r.RolId, d.DepartamentoId
    FROM dbo.Roles r CROSS JOIN dbo.Departamentos d
    WHERE r.Nombre = N'Administrador' AND d.Nombre = N'Sistemas';
END;

IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios WHERE Correo = N'tecnico@mesaayuda.local')
BEGIN
    INSERT dbo.Usuarios(NombreCompleto, Correo, PasswordHash, RolId, DepartamentoId)
    SELECT N'Soporte Nivel 1', N'tecnico@mesaayuda.local',
           LOWER(CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'Tecnico123*'), 2)),
           r.RolId, d.DepartamentoId
    FROM dbo.Roles r CROSS JOIN dbo.Departamentos d
    WHERE r.Nombre = N'Tecnico' AND d.Nombre = N'Sistemas';
END;

IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios WHERE Correo = N'empleado@mesaayuda.local')
BEGIN
    INSERT dbo.Usuarios(NombreCompleto, Correo, PasswordHash, RolId, DepartamentoId)
    SELECT N'Usuario de Prueba', N'empleado@mesaayuda.local',
           LOWER(CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'Empleado123*'), 2)),
           r.RolId, d.DepartamentoId
    FROM dbo.Roles r CROSS JOIN dbo.Departamentos d
    WHERE r.Nombre = N'Empleado' AND d.Nombre = N'Operaciones';
END;
GO

IF COL_LENGTH(N'dbo.Tickets', N'PersonaBeneficiaria') IS NULL
    ALTER TABLE dbo.Tickets ADD PersonaBeneficiaria NVARCHAR(150) NULL;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios WHERE Correo = N'anthony@mesaayuda.local')
BEGIN
    INSERT dbo.Usuarios(NombreCompleto, Correo, PasswordHash, RolId, DepartamentoId)
    SELECT N'Anthony Gomez', N'anthony@mesaayuda.local',
        LOWER(CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'Anthony123*'), 2)), r.RolId, d.DepartamentoId
    FROM dbo.Roles r CROSS JOIN dbo.Departamentos d
    WHERE r.Nombre = N'Administrador' AND d.Nombre = N'Sistemas';
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_CalcularHashTicket
(
    @UsuarioId INT,
    @DepartamentoId INT,
    @CategoriaId INT,
    @PrioridadId INT,
    @Descripcion NVARCHAR(2000),
    @FechaCreacion DATETIME2(0),
    @EstadoId INT,
    @TecnicoId INT,
    @PersonaBeneficiaria NVARCHAR(150)
)
RETURNS CHAR(64)
AS
BEGIN
    DECLARE @Contenido NVARCHAR(MAX) = CONCAT(
        @UsuarioId, N'|', @DepartamentoId, N'|', @CategoriaId, N'|', @PrioridadId, N'|',
        @Descripcion, N'|', CONVERT(NVARCHAR(19), @FechaCreacion, 126), N'|',
        @EstadoId, N'|', COALESCE(CONVERT(NVARCHAR(20), @TecnicoId), N'NULL'),
        CASE WHEN @PersonaBeneficiaria IS NULL THEN N'' ELSE CONCAT(N'|', @PersonaBeneficiaria) END
    );

    RETURN LOWER(CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', @Contenido), 2));
END;
GO

CREATE OR ALTER TRIGGER dbo.tr_Tickets_Auditoria
ON dbo.Tickets
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UsuarioContexto INT = TRY_CONVERT(INT, SESSION_CONTEXT(N'UsuarioId'));
    DECLARE @Nota NVARCHAR(500) = TRY_CONVERT(NVARCHAR(500), SESSION_CONTEXT(N'NotaAuditoria'));

    INSERT dbo.BitacoraTickets
    (
        TicketId, UsuarioId, Operacion, Fecha, Cambios, ValoresAnteriores, ValoresNuevos
    )
    SELECT
        COALESCE(i.TicketId, d.TicketId),
        COALESCE(@UsuarioContexto, i.UsuarioSolicitanteId, d.UsuarioSolicitanteId),
        CASE
            WHEN d.TicketId IS NULL THEN N'INSERTAR'
            WHEN i.TicketId IS NULL THEN N'ELIMINAR'
            ELSE N'ACTUALIZAR'
        END,
        SYSDATETIME(),
        CASE
            WHEN d.TicketId IS NULL THEN CONCAT(N'Ticket ', i.Numero, N' registrado.')
            WHEN i.TicketId IS NULL THEN CONCAT(N'Ticket ', d.Numero, N' eliminado.')
            ELSE CONCAT(
                N'Estado ID: ', d.EstadoId, N' -> ', i.EstadoId,
                N'; Tecnico ID: ', COALESCE(CONVERT(NVARCHAR(20), d.TecnicoAsignadoId), N'Sin asignar'),
                N' -> ', COALESCE(CONVERT(NVARCHAR(20), i.TecnicoAsignadoId), N'Sin asignar'),
                CASE WHEN @Nota IS NULL THEN N'' ELSE CONCAT(N'; Nota: ', @Nota) END
            )
        END,
        CASE WHEN d.TicketId IS NULL THEN NULL ELSE
            (SELECT d.Numero, d.DepartamentoId, d.CategoriaId, d.PrioridadId, d.Descripcion, d.PersonaBeneficiaria,
                    d.EstadoId, d.TecnicoAsignadoId, d.FechaCierre, d.HashIntegridad
             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END,
        CASE WHEN i.TicketId IS NULL THEN NULL ELSE
            (SELECT i.Numero, i.DepartamentoId, i.CategoriaId, i.PrioridadId, i.Descripcion, i.PersonaBeneficiaria,
                    i.EstadoId, i.TecnicoAsignadoId, i.FechaCierre, i.HashIntegridad
             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END
    FROM inserted i
    FULL OUTER JOIN deleted d ON d.TicketId = i.TicketId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_UsuarioAutenticar
    @Correo NVARCHAR(150),
    @PasswordHash CHAR(64)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT u.UsuarioId, u.NombreCompleto, u.Correo, r.Nombre AS Rol
    FROM dbo.Usuarios u
    INNER JOIN dbo.Roles r ON r.RolId = u.RolId
    WHERE u.Correo = @Correo
      AND u.PasswordHash = @PasswordHash
      AND u.Activo = 1
      AND r.Activo = 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_CatalogosListar
AS
BEGIN
    SET NOCOUNT ON;

    SELECT DepartamentoId AS Id, Nombre FROM dbo.Departamentos WHERE Activo = 1 ORDER BY Nombre;
    SELECT CategoriaId AS Id, Nombre FROM dbo.Categorias WHERE Activo = 1 ORDER BY Nombre;
    SELECT PrioridadId AS Id, Nombre FROM dbo.Prioridades WHERE Activo = 1 ORDER BY Nivel;
    SELECT EstadoId AS Id, Nombre FROM dbo.Estados WHERE Activo = 1 ORDER BY EstadoId;

    SELECT u.UsuarioId AS Id, u.NombreCompleto AS Nombre
    FROM dbo.Usuarios u
    INNER JOIN dbo.Roles r ON r.RolId = u.RolId
    WHERE u.Activo = 1 AND r.Nombre IN (N'Administrador', N'Tecnico')
    ORDER BY u.NombreCompleto;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TicketCrear
    @UsuarioId INT,
    @DepartamentoId INT,
    @CategoriaId INT,
    @PrioridadId INT,
    @Descripcion NVARCHAR(2000),
    @PersonaBeneficiaria NVARCHAR(150)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NULLIF(LTRIM(RTRIM(@PersonaBeneficiaria)), N'') IS NULL
        THROW 50006, 'Indique la persona que necesita ayuda.', 1;
    SET @PersonaBeneficiaria = LTRIM(RTRIM(@PersonaBeneficiaria));

    IF LEN(LTRIM(RTRIM(@Descripcion))) < 10
        THROW 50001, 'La descripcion debe contener al menos 10 caracteres.', 1;

    DECLARE @TicketId INT = NEXT VALUE FOR dbo.SecuenciaTickets;
    DECLARE @Numero VARCHAR(20) = CONCAT('TK-', RIGHT(CONCAT('000000', @TicketId), 6));
    DECLARE @Fecha DATETIME2(0) = SYSDATETIME();
    DECLARE @EstadoId INT = (SELECT EstadoId FROM dbo.Estados WHERE Nombre = N'Abierto' AND Activo = 1);
    DECLARE @Hash CHAR(64) = dbo.fn_CalcularHashTicket(
        @UsuarioId, @DepartamentoId, @CategoriaId, @PrioridadId,
        LTRIM(RTRIM(@Descripcion)), @Fecha, @EstadoId, NULL, @PersonaBeneficiaria
    );

    EXEC sys.sp_set_session_context @key = N'UsuarioId', @value = @UsuarioId;
    EXEC sys.sp_set_session_context @key = N'NotaAuditoria', @value = N'Registro inicial del ticket.';

    INSERT dbo.Tickets
    (
        TicketId, Numero, UsuarioSolicitanteId, DepartamentoId, CategoriaId,
        PrioridadId, Descripcion, FechaCreacion, EstadoId, TecnicoAsignadoId,
        FechaCierre, HashIntegridad, PersonaBeneficiaria
    )
    VALUES
    (
        @TicketId, @Numero, @UsuarioId, @DepartamentoId, @CategoriaId,
        @PrioridadId, LTRIM(RTRIM(@Descripcion)), @Fecha, @EstadoId, NULL,
        NULL, @Hash, @PersonaBeneficiaria
    );

    SELECT @TicketId AS TicketId, @Numero AS Numero, @Hash AS HashIntegridad;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TicketsListar
    @UsuarioId INT,
    @EsAdministrador BIT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        t.TicketId, t.Numero, t.FechaCreacion,
        solicitante.NombreCompleto AS Solicitante, t.PersonaBeneficiaria,
        d.Nombre AS Departamento, c.Nombre AS Categoria,
        p.PrioridadId, p.Nombre AS Prioridad,
        e.EstadoId, e.Nombre AS Estado,
        tecnico.UsuarioId AS TecnicoId, tecnico.NombreCompleto AS Tecnico,
        t.Descripcion, t.HashIntegridad,
        CONVERT(BIT, CASE WHEN t.HashIntegridad = dbo.fn_CalcularHashTicket(
            t.UsuarioSolicitanteId, t.DepartamentoId, t.CategoriaId, t.PrioridadId,
            t.Descripcion, t.FechaCreacion, t.EstadoId, t.TecnicoAsignadoId, t.PersonaBeneficiaria
        ) THEN 1 ELSE 0 END) AS HashValido
    FROM dbo.Tickets t
    INNER JOIN dbo.Usuarios solicitante ON solicitante.UsuarioId = t.UsuarioSolicitanteId
    INNER JOIN dbo.Departamentos d ON d.DepartamentoId = t.DepartamentoId
    INNER JOIN dbo.Categorias c ON c.CategoriaId = t.CategoriaId
    INNER JOIN dbo.Prioridades p ON p.PrioridadId = t.PrioridadId
    INNER JOIN dbo.Estados e ON e.EstadoId = t.EstadoId
    LEFT JOIN dbo.Usuarios tecnico ON tecnico.UsuarioId = t.TecnicoAsignadoId
    WHERE @EsAdministrador = 1 OR t.UsuarioSolicitanteId = @UsuarioId
    ORDER BY t.FechaCreacion DESC, t.TicketId DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TicketsResumen
    @UsuarioId INT,
    @EsAdministrador BIT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        COUNT(*) AS Total,
        COALESCE(SUM(CASE WHEN p.Nombre = N'Alta' AND e.EsFinal = 0 THEN 1 ELSE 0 END), 0) AS Urgentes,
        COALESCE(SUM(CASE WHEN e.Nombre = N'En Proceso' THEN 1 ELSE 0 END), 0) AS EnProceso,
        COALESCE(SUM(CASE WHEN e.EsFinal = 1 AND CONVERT(DATE, t.FechaCierre) = CONVERT(DATE, SYSDATETIME()) THEN 1 ELSE 0 END), 0) AS ResueltosHoy
    FROM dbo.Tickets t
    INNER JOIN dbo.Prioridades p ON p.PrioridadId = t.PrioridadId
    INNER JOIN dbo.Estados e ON e.EstadoId = t.EstadoId
    WHERE @EsAdministrador = 1 OR t.UsuarioSolicitanteId = @UsuarioId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_BitacoraListar
    @UsuarioId INT,
    @EsAdministrador BIT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (100)
        b.BitacoraId,
        COALESCE(t.Numero, CONCAT('Ticket ID ', b.TicketId)) AS NumeroTicket,
        COALESCE(u.NombreCompleto, N'Sistema') AS Usuario,
        b.Operacion,
        b.Fecha,
        b.Cambios
    FROM dbo.BitacoraTickets b
    LEFT JOIN dbo.Tickets t ON t.TicketId = b.TicketId
    LEFT JOIN dbo.Usuarios u ON u.UsuarioId = b.UsuarioId
    WHERE @EsAdministrador = 1 OR t.UsuarioSolicitanteId = @UsuarioId
    ORDER BY b.Fecha DESC, b.BitacoraId DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TicketActualizar
    @TicketId INT,
    @TecnicoId INT = NULL,
    @EstadoId INT,
    @Nota NVARCHAR(500) = NULL,
    @UsuarioAccionId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Usuarios u
        INNER JOIN dbo.Roles r ON r.RolId = u.RolId
        WHERE u.UsuarioId = @UsuarioAccionId
          AND u.Activo = 1
          AND r.Nombre IN (N'Administrador', N'Tecnico')
    )
        THROW 50002, 'El usuario no tiene permisos para administrar tickets.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.Tickets WHERE TicketId = @TicketId)
        THROW 50003, 'El ticket indicado no existe.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.Estados WHERE EstadoId = @EstadoId AND Activo = 1)
        THROW 50004, 'El estado indicado no es valido.', 1;

    IF @TecnicoId IS NOT NULL AND NOT EXISTS
    (
        SELECT 1
        FROM dbo.Usuarios u
        INNER JOIN dbo.Roles r ON r.RolId = u.RolId
        WHERE u.UsuarioId = @TecnicoId AND u.Activo = 1
          AND r.Nombre IN (N'Administrador', N'Tecnico')
    )
        THROW 50005, 'El tecnico indicado no es valido.', 1;

    DECLARE @EsFinal BIT = (SELECT EsFinal FROM dbo.Estados WHERE EstadoId = @EstadoId);
    DECLARE @Hash CHAR(64);

    SELECT @Hash = dbo.fn_CalcularHashTicket(
        UsuarioSolicitanteId, DepartamentoId, CategoriaId, PrioridadId,
        Descripcion, FechaCreacion, @EstadoId, @TecnicoId, PersonaBeneficiaria
    )
    FROM dbo.Tickets
    WHERE TicketId = @TicketId;

    EXEC sys.sp_set_session_context @key = N'UsuarioId', @value = @UsuarioAccionId;
    EXEC sys.sp_set_session_context @key = N'NotaAuditoria', @value = @Nota;

    UPDATE dbo.Tickets
    SET TecnicoAsignadoId = @TecnicoId,
        EstadoId = @EstadoId,
        FechaCierre = CASE WHEN @EsFinal = 1 THEN COALESCE(FechaCierre, SYSDATETIME()) ELSE NULL END,
        HashIntegridad = @Hash
    WHERE TicketId = @TicketId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_EvidenciaCrear
    @TicketId INT,
    @UsuarioId INT,
    @NombreOriginal NVARCHAR(255),
    @RutaRelativa NVARCHAR(500),
    @TipoContenido NVARCHAR(100),
    @TamanioBytes BIGINT,
    @HashArchivo CHAR(64)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Tickets t
        INNER JOIN dbo.Usuarios u ON u.UsuarioId = @UsuarioId AND u.Activo = 1
        INNER JOIN dbo.Roles r ON r.RolId = u.RolId
        WHERE t.TicketId = @TicketId
          AND (t.UsuarioSolicitanteId = @UsuarioId OR r.Nombre IN (N'Administrador', N'Tecnico'))
    )
        THROW 50006, 'No tiene permisos para adjuntar evidencia a este ticket.', 1;

    INSERT dbo.Evidencias
    (
        TicketId, NombreOriginal, RutaRelativa, TipoContenido,
        TamanioBytes, HashArchivo, UsuarioId
    )
    VALUES
    (
        @TicketId, @NombreOriginal, @RutaRelativa, @TipoContenido,
        @TamanioBytes, @HashArchivo, @UsuarioId
    );
END;
GO

UPDATE dbo.BitacoraTickets
SET Cambios = REPLACE(
    TRANSLATE(
        Cambios,
        NCHAR(225) + NCHAR(233) + NCHAR(237) + NCHAR(243) + NCHAR(250) +
        NCHAR(193) + NCHAR(201) + NCHAR(205) + NCHAR(211) + NCHAR(218) +
        NCHAR(241) + NCHAR(209) + NCHAR(252) + NCHAR(220),
        N'aeiouAEIOUnNuU'
    ),
    NCHAR(8594),
    N'->'
);
GO

SELECT N'MesaAyudaDb instalada correctamente.' AS Resultado;
SELECT N'admin@mesaayuda.local' AS Usuario, N'Admin123*' AS Clave, N'Administrador' AS Rol
UNION ALL SELECT N'tecnico@mesaayuda.local', N'Tecnico123*', N'Tecnico'
UNION ALL SELECT N'empleado@mesaayuda.local', N'Empleado123*', N'Empleado';
GO
