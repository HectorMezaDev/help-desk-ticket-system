namespace MesaAyuda.Backend.Dtos
{
    public class TicketActualizarDto
    {
        public int TicketId { get; set; }
        public int? TecnicoId { get; set; }
        public int EstadoId { get; set; }
        public string Nota { get; set; }
        public int UsuarioAccionId { get; set; }
    }
}
