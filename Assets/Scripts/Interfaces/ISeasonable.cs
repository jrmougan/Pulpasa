public interface ISeasonable
{
    void ApplySeasoning(SpicesSO seasoning);
    bool CanReceiveSeasoning(SpicesSO seasoning);
}