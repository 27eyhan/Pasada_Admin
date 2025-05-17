# AI Integration with Database

This implementation connects the Gemini API with Pasada's Supabase database to provide data-driven suggestions for administrators. This README explains the architecture and flow of the implementation.

## Architecture

1. **Database Summary Service** (`database_summary_service.dart`)
   - Singleton service that connects to Supabase
   - Provides methods to fetch and summarize data from four key tables:
     - Bookings (ride status, fares)
     - Drivers (active/inactive status)
     - Routes (origin and destination points)
     - Vehicles (with associations to drivers)

2. **AI Chat Integration** (`ai_chat.dart`)
   - Uses the Database Summary Service to fetch current system data
   - Enhances the system prompt with real-time database context
   - Maintains the existing chat interface and response format

## Data Flow

1. When a user asks a question in the AI chat:
   - The app calls `getFullDatabaseContext()` to fetch current database metrics
   - This data is formatted as a concise text summary (SYSTEM DATA SUMMARY)
   - The summary is injected into the enhanced system prompt for Gemini

2. The enhanced prompt contains:
   - Original system instructions about Pasada and the AI assistant role
   - Current database metrics (bookings status counts, driver availability, etc.)
   - User's specific question

3. Gemini processes this combined context and generates a response that:
   - Takes into account the current system state
   - Provides data-informed suggestions
   - Maintains the 3-sentence limit for concise answers

## Important Considerations

- **Privacy**: The service avoids including sensitive data by only sharing aggregate counts and statistics
- **Geographical Data**: Location data is simplified to origin/destination names rather than raw coordinates
- **Error Handling**: The service is designed to continue functioning even if some data sections fail
- **Resilience**: If a section fails, the summary will include data from the successful sections only

## Maintenance

When updating the database schema:
1. Update the corresponding methods in `DatabaseSummaryService` class
2. Ensure new tables are represented in the summary if relevant
3. Test that the changes don't break the AI's understanding of the data

## Example Usage

An admin might ask:
- "How many rides were completed today?"
- "How many drivers are currently active?"
- "What's the status of our vehicle fleet?"
- "Which route is being serviced right now?"

The AI will provide answers based on the actual system data rather than generic responses. 