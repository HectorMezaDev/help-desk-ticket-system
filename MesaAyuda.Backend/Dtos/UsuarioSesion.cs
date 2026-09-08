namespace MesaAyuda.Backend.Dtos
{
    public class UsuarioSesion
    {
        public int UsuarioId { get; set; }
        public string NombreCompleto { get; set; }
        public string Correo { get; set; }
        public string Rol { get; set; }

        public bool EsAdministrador
        {
            get { return Rol == "Administrador" || Rol == "Tecnico"; }
        }
    }
}
