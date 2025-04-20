public interface ISeasonable
{
    void ApplySeasoning(SeasoningData seasoning);
    bool CanReceiveSeasoning(SeasoningData seasoning);
}