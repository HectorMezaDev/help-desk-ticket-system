namespace MesaAyuda.Backend.Dtos
{
    public class TicketCrearDto
    {
        public int UsuarioId { get; set; }
        public int DepartamentoId { get; set; }
        public int CategoriaId { get; set; }
        public int PrioridadId { get; set; }
        public string PersonaBeneficiaria { get; set; }
        public string Descripcion { get; set; }
    }
}
