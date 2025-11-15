# Architecture Diagram

## System Architecture - Geospatial + Key-Value Integration

```
┌─────────────────────────────────────────────────────────────────────┐
│                           CLIENT LAYER                              │
│                                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │ Postman  │  │  cURL    │  │  Browser │  │Mobile App│          │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘          │
└───────┼─────────────┼─────────────┼─────────────┼─────────────────┘
        │             │             │             │
        └─────────────┴─────────────┴─────────────┘
                      │
                      │ HTTP/REST
                      ↓
┌─────────────────────────────────────────────────────────────────────┐
│                        APPLICATION LAYER                            │
│                         (Node.js + Express)                         │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │                      API Routes                               │ │
│  │  GET /                 → Documentation                        │ │
│  │  GET /health           → Health Check                         │ │
│  │  GET /api/nearby       → Geospatial Search                    │ │
│  └───────────────────────────┬───────────────────────────────────┘ │
│                              │                                     │
│  ┌───────────────────────────┴───────────────────────────────────┐ │
│  │                     Controller Layer                          │ │
│  │                    (geoController.js)                         │ │
│  │                                                               │ │
│  │  • Request Validation                                         │ │
│  │  • Cache-Aside Pattern Implementation                         │ │
│  │  • Response Formatting                                        │ │
│  └───────────────┬───────────────────────────┬───────────────────┘ │
│                  │                           │                     │
│                  ↓                           ↓                     │
│  ┌───────────────────────────┐  ┌───────────────────────────────┐ │
│  │    Redis Service          │  │    PostGIS Service            │ │
│  │  (redisService.js)        │  │  (postgisService.js)          │ │
│  │                           │  │                               │ │
│  │  • generateCacheKey()     │  │  • findNearbyPsychologists()  │ │
│  │  • get()                  │  │  • checkPostGISExtension()    │ │
│  │  • set()                  │  │                               │ │
│  │  • delete()               │  │  Uses:                        │ │
│  │  • flushAll()             │  │  • ST_Point()                 │ │
│  └─────────┬─────────────────┘  │  • ST_DWithin()               │ │
│            │                    │  • ST_Distance()              │ │
│            │                    └─────────┬─────────────────────┘ │
└────────────┼──────────────────────────────┼───────────────────────┘
             │                              │
             │                              │
             ↓                              ↓
┌──────────────────────────┐  ┌──────────────────────────────────────┐
│     DATA LAYER (Cache)   │  │      DATA LAYER (Persistent)         │
│                          │  │                                      │
│  ┌────────────────────┐  │  │  ┌────────────────────────────────┐ │
│  │      Redis         │  │  │  │  PostgreSQL + PostGIS          │ │
│  │  (Key-Value Store) │  │  │  │  (Relational + Geospatial)     │ │
│  │                    │  │  │  │                                │ │
│  │  Key Pattern:      │  │  │  │  Table: psicologos             │ │
│  │  geo:search:       │  │  │  │  ├─ id (SERIAL)                │ │
│  │    lat:<lat>:      │  │  │  │  ├─ nome (TEXT)                │ │
│  │    lng:<lng>:      │  │  │  │  ├─ crp (TEXT)                 │ │
│  │    radius:<km>     │  │  │  │  ├─ especialidade (TEXT)       │ │
│  │                    │  │  │  │  └─ localizacao (GEOGRAPHY)    │ │
│  │  TTL: 300s (5min)  │  │  │  │                                │ │
│  │                    │  │  │  │  Index: GIST (localizacao)     │ │
│  └────────────────────┘  │  │  └────────────────────────────────┘ │
└──────────────────────────┘  └──────────────────────────────────────┘


                        FLOW DIAGRAM

┌────────────────────────────────────────────────────────────────────┐
│                    REQUEST FLOW                                    │
└────────────────────────────────────────────────────────────────────┘

  1. Client Request
     │
     ↓
  2. Controller receives: lat, lng, radius
     │
     ↓
  3. Generate Cache Key: geo:search:lat:<lat>:lng:<lng>:radius:<km>
     │
     ↓
  4. Check Redis Cache
     │
     ├─→ [CACHE HIT] ──→ Return from Redis (2-5ms)
     │                   └─→ Response to Client
     │
     └─→ [CACHE MISS]
         │
         ↓
      5. Query PostGIS
         │
         SELECT * FROM psicologos
         WHERE ST_DWithin(
           localizacao::geography,
           ST_Point(lng, lat)::geography,
           radius * 1000
         )
         │
         ↓
      6. Store in Redis (TTL: 300s)
         │
         ↓
      7. Return to Client (40-60ms)


                    CACHE-ASIDE PATTERN

┌──────────────┐
│   Request    │
└──────┬───────┘
       │
       ↓
┌──────────────────┐         ┌─────────────┐
│  Check Cache     │────YES──│   Return    │
│  (Redis)         │         │   Cached    │
└──────┬───────────┘         └─────────────┘
       │ NO
       ↓
┌──────────────────┐
│  Query Database  │
│  (PostGIS)       │
└──────┬───────────┘
       │
       ↓
┌──────────────────┐
│  Save to Cache   │
│  (Redis + TTL)   │
└──────┬───────────┘
       │
       ↓
┌──────────────────┐
│  Return Result   │
└──────────────────┘


                TECHNOLOGY STACK

┌─────────────────────────────────────────────────────┐
│ Layer           │ Technology                        │
├─────────────────────────────────────────────────────┤
│ Runtime         │ Node.js 16+                       │
│ Web Framework   │ Express.js 4.18                   │
│ Geospatial DB   │ PostgreSQL 14+ + PostGIS 3.0+     │
│ Cache DB        │ Redis 7.0+                        │
│ PostgreSQL Client│ pg 8.11                          │
│ Redis Client    │ redis 4.6                         │
│ Configuration   │ dotenv 16.3                       │
└─────────────────────────────────────────────────────┘


              KEY FEATURES

┌──────────────────────────────────────────────────┐
│ ✅ Geospatial Queries                           │
│    • ST_Point: Create geographic points          │
│    • ST_DWithin: Find within radius              │
│    • ST_Distance: Calculate distances            │
│                                                  │
│ ✅ High-Performance Caching                     │
│    • In-memory storage (Redis)                   │
│    • Automatic expiration (TTL)                  │
│    • 10-20x faster response times                │
│                                                  │
│ ✅ RESTful API                                  │
│    • Clear endpoint structure                    │
│    • JSON responses                              │
│    • Error handling                              │
│                                                  │
│ ✅ Polyglot Persistence                         │
│    • Right tool for right job                    │
│    • PostGIS: Complex spatial queries            │
│    • Redis: Fast temporary storage               │
└──────────────────────────────────────────────────┘
```

## How to Create a Visual Diagram

To create a professional PNG diagram, you can use:

1. **Draw.io (diagrams.net)**: https://app.diagrams.net/
2. **Lucidchart**: https://www.lucidchart.com/
3. **Microsoft Visio**
4. **PlantUML**: For code-based diagrams
5. **Excalidraw**: https://excalidraw.com/

### Recommended Tools Installation:

**For ASCII to PNG conversion:**
```bash
npm install -g asciiflow
```

**For PlantUML (requires Java):**
```bash
# Install PlantUML
sudo apt install plantuml  # Linux
brew install plantuml      # macOS
```

Save this file as `architecture-diagram.png` after creating it with one of the tools above.

