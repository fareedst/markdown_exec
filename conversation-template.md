# STDD Conversation Template: Adding a Feature to an Existing Complex Application

**STDD Methodology Version**: 1.0.0

This template demonstrates a realistic conversation between a developer and an AI-coder following the STDD methodology when adding a feature to an existing, complex application.

---

## Scenario: Adding Rate Limiting to API Endpoints

### Context
- **Existing Application**: REST API service with multiple endpoints
- **Feature Request**: Add rate limiting to prevent abuse
- **Complexity**: Requires integration with existing middleware, configuration, and monitoring

---

## Conversation Flow

### 🎯 Phase 1: Requirements → Pseudo-Code (NO CODE YET)

#### Developer Request

**Developer**: "I need to add rate limiting to our API endpoints. We're getting hit with too many requests from some clients and it's affecting performance. Can you help implement this?"

---

#### AI Response: Acknowledgment and Planning Phase

**AI**: "Observing AI principles!"

I'll help you add rate limiting to your API endpoints. Following STDD methodology, let me first understand the requirements and document the approach before writing any code.

**Questions to clarify requirements:**

1. **Rate limiting scope**: Should this apply to all endpoints, or specific endpoints? Do we need different limits for different endpoints?

2. **Rate limiting algorithm**: What approach do you prefer?
   - Token bucket
   - Fixed window
   - Sliding window
   - Leaky bucket

3. **Storage**: Where should we store rate limit counters?
   - In-memory (simple, but lost on restart)
   - Redis (distributed, persistent)
   - Database (persistent, but slower)

4. **Response behavior**: When rate limit is exceeded, should we:
   - Return HTTP 429 (Too Many Requests)
   - Include retry-after headers
   - Log the event

5. **Configuration**: Should rate limits be:
   - Hard-coded
   - Configurable via config file
   - Per-user/API key based

6. **Monitoring**: Do you need metrics/logging for rate limit hits?

Please provide answers to these questions, or I can proceed with reasonable defaults based on best practices.

---

#### Developer Response

**Developer**: "Let me answer your questions:

1. Apply to all endpoints, but allow different limits per endpoint
2. Token bucket algorithm - it's more flexible
3. Redis - we already have it in our stack
4. Return HTTP 429 with Retry-After header, and log it
5. Configurable via config file, with per-endpoint overrides
6. Yes, we need metrics for monitoring

Also, we need to exempt certain API keys (admin keys) from rate limiting."

---

#### AI Response: Phase 1 - Requirements Documentation

**AI**: "Observing AI principles!"

Perfect! Let me document the requirements with satisfaction and validation criteria, then work through architecture and implementation decisions. **No code changes yet** - this is the planning phase.

I'll now:
1. Add the requirement to `requirements.md` with satisfaction and validation criteria
2. Document architecture decisions in `architecture-decisions.md`
3. Document implementation decisions in `implementation-decisions.md`
4. Update `semantic-tokens.md` with new tokens
5. Create tasks in `tasks.md`

Let me start:

---

**AI** (updating documentation):

I've documented the requirement `[REQ:RATE_LIMITING]` in `requirements.md` with:

- **Description**: Rate limiting for all API endpoints with configurable limits
- **Rationale**: Prevent abuse and ensure fair resource usage
- **Satisfaction Criteria**:
  - Rate limiting applies to all endpoints by default
  - Per-endpoint rate limit configuration supported
  - Token bucket algorithm implemented
  - Redis storage for rate limit counters
  - HTTP 429 response with Retry-After header when limit exceeded
  - Admin API keys exempt from rate limiting
  - Rate limit events logged
  - Metrics exposed for monitoring

- **Validation Criteria**:
  - Unit tests for token bucket algorithm
  - Integration tests for rate limiting middleware
  - Tests for HTTP 429 response and headers
  - Tests for admin key exemption
  - Load tests to verify rate limiting behavior
  - Manual verification of metrics and logging

---

**AI** (continuing):

Now documenting architecture decisions in `architecture-decisions.md`:

I've added `[ARCH:RATE_LIMITING_MIDDLEWARE]` which:
- Uses middleware pattern to intercept requests before handlers
- Integrates with existing middleware chain
- References `[REQ:RATE_LIMITING]`

I've added `[ARCH:TOKEN_BUCKET_ALGORITHM]` which:
- Implements token bucket for flexible rate limiting
- References `[REQ:RATE_LIMITING]`

I've added `[ARCH:REDIS_STORAGE]` which:
- Uses Redis for distributed rate limit counter storage
- References `[REQ:RATE_LIMITING]`

I've added `[ARCH:CONFIGURATION_MANAGEMENT]` which:
- Extends existing config structure for rate limit settings
- Supports per-endpoint overrides
- References `[REQ:RATE_LIMITING]`

---

**AI** (continuing):

Now documenting implementation decisions in `implementation-decisions.md`:

I've added `[IMPL:TOKEN_BUCKET_STRUCT]` which:
- Defines data structure for token bucket state
- References `[ARCH:TOKEN_BUCKET_ALGORITHM]` and `[REQ:RATE_LIMITING]`

I've added `[IMPL:RATE_LIMIT_MIDDLEWARE_FUNC]` which:
- Implements middleware function signature
- References `[ARCH:RATE_LIMITING_MIDDLEWARE]` and `[REQ:RATE_LIMITING]`

I've added `[IMPL:REDIS_COUNTER_KEYS]` which:
- Defines Redis key naming strategy for rate limit counters
- References `[ARCH:REDIS_STORAGE]` and `[REQ:RATE_LIMITING]`

I've added `[IMPL:ADMIN_KEY_EXEMPTION]` which:
- Implements logic to check and exempt admin API keys
- References `[ARCH:RATE_LIMITING_MIDDLEWARE]` and `[REQ:RATE_LIMITING]`

I've added `[IMPL:METRICS_EXPOSURE]` which:
- Integrates with existing metrics system
- References `[ARCH:RATE_LIMITING_MIDDLEWARE]` and `[REQ:RATE_LIMITING]`

---

**AI** (continuing):

Updated `semantic-tokens.md` with all new tokens and their relationships.

Now creating tasks in `tasks.md`:

I've created the following tasks with priorities:

**P0 Tasks (Critical)**:
- `[REQ:RATE_LIMITING]` Implement token bucket algorithm core logic
- `[REQ:RATE_LIMITING]` Implement rate limiting middleware
- `[REQ:RATE_LIMITING]` Write unit tests for token bucket

**P1 Tasks (Important)**:
- `[REQ:RATE_LIMITING]` Integrate Redis storage
- `[REQ:RATE_LIMITING]` Add configuration support
- `[REQ:RATE_LIMITING]` Implement admin key exemption
- `[REQ:RATE_LIMITING]` Write integration tests

**P2 Tasks (Nice-to-Have)**:
- `[REQ:RATE_LIMITING]` Add metrics and logging
- `[REQ:RATE_LIMITING]` Add per-endpoint configuration

---

**AI** (pseudo-code):

Here's the pseudo-code approach:

```text
// [REQ:RATE_LIMITING] Rate Limiting Middleware
// [ARCH:RATE_LIMITING_MIDDLEWARE] [IMPL:RATE_LIMIT_MIDDLEWARE_FUNC]
function rateLimitMiddleware(config, redisClient):
    return function(next):
        return function(request, response):
            // [IMPL:ADMIN_KEY_EXEMPTION] Check if admin key
            if isAdminKey(request.apiKey):
                return next(request, response)
            
            // [IMPL:REDIS_COUNTER_KEYS] Get endpoint-specific config
            endpointConfig = getEndpointConfig(request.path, config)
            
            // [IMPL:TOKEN_BUCKET_STRUCT] Check rate limit
            allowed = checkTokenBucket(
                redisClient,
                request.apiKey,
                request.path,
                endpointConfig.limit,
                endpointConfig.window
            )
            
            if not allowed:
                // [REQ:RATE_LIMITING] Return 429 with Retry-After
                response.status = 429
                response.headers["Retry-After"] = calculateRetryAfter(...)
                // [REQ:RATE_LIMITING] Log event
                logRateLimitExceeded(request)
                // [IMPL:METRICS_EXPOSURE] Record metric
                recordMetric("rate_limit_exceeded")
                return response
            
            // [REQ:RATE_LIMITING] Continue to next handler
            return next(request, response)

// [REQ:RATE_LIMITING] Token Bucket Algorithm
// [ARCH:TOKEN_BUCKET_ALGORITHM] [IMPL:TOKEN_BUCKET_STRUCT]
function checkTokenBucket(redis, key, path, limit, window):
    bucketKey = formatRedisKey(key, path)
    currentTime = now()
    
    // Get current bucket state from Redis
    bucket = redis.get(bucketKey)
    
    if bucket is null:
        // Initialize new bucket
        bucket = {tokens: limit, lastRefill: currentTime}
        redis.set(bucketKey, bucket, ttl=window)
        return true
    
    // Refill tokens based on elapsed time
    elapsed = currentTime - bucket.lastRefill
    tokensToAdd = (elapsed / window) * limit
    bucket.tokens = min(limit, bucket.tokens + tokensToAdd)
    bucket.lastRefill = currentTime
    
    // Check if request can be allowed
    if bucket.tokens >= 1:
        bucket.tokens -= 1
        redis.set(bucketKey, bucket, ttl=window)
        return true
    else:
        return false
```

---

**AI** (summary):

**Planning Phase Complete - Ready for Review**

I've completed Phase 1 of STDD:

✅ **Requirements documented** in `requirements.md` with satisfaction and validation criteria  
✅ **Architecture decisions** documented in `architecture-decisions.md` with `[ARCH:*]` tokens  
✅ **Implementation decisions** documented in `implementation-decisions.md` with `[IMPL:*]` tokens  
✅ **Semantic tokens** registered in `semantic-tokens.md`  
✅ **Tasks created** in `tasks.md` with priorities  
✅ **Pseudo-code** provided showing the approach

**No code has been written yet** - this follows STDD's documentation-first approach.

Please review the documentation and let me know if you'd like any changes before I proceed to Phase 2 (task breakdown) and Phase 3 (implementation).

---

### ✅ Developer Approval

**Developer**: "This looks good! The approach makes sense. One clarification: for the token bucket, can we make the refill rate configurable too? So we can have different refill rates for different endpoints."

---

### 🔄 AI Response: Updating Requirements

**AI**: "Observing AI principles!"

Good catch! Let me update the requirements and architecture decisions to include configurable refill rates.

**AI** (updating documentation):

Updated `requirements.md`:
- Added to satisfaction criteria: "Refill rate configurable per endpoint"
- Added to validation criteria: "Tests for different refill rates"

Updated `architecture-decisions.md`:
- Enhanced `[ARCH:TOKEN_BUCKET_ALGORITHM]` to include configurable refill rate
- Enhanced `[ARCH:CONFIGURATION_MANAGEMENT]` to include refill rate in config

Updated `implementation-decisions.md`:
- Enhanced `[IMPL:TOKEN_BUCKET_STRUCT]` to include refill rate parameter

Updated pseudo-code to show refill rate calculation using config value.

Ready to proceed to Phase 2?

---

**Developer**: "Yes, proceed!"

---

### 📋 Phase 2: Pseudo-Code → Tasks (Task Breakdown)

**AI**: "Observing AI principles!"

Breaking down tasks into implementable subtasks in `tasks.md`. Each subtask is a single, complete unit of work.

**AI** (updating tasks.md):

I've broken down each task into subtasks:

**P0: Implement token bucket algorithm core logic [REQ:RATE_LIMITING]**
- [ ] Create `TokenBucket` struct with fields: tokens, lastRefill, limit, refillRate
- [ ] Implement `NewTokenBucket(limit, refillRate)` constructor
- [ ] Implement `AllowRequest()` method that checks and consumes tokens
- [ ] Implement `RefillTokens()` method that calculates and adds tokens based on elapsed time
- [ ] Write unit test `TestTokenBucket_REQ_RATE_LIMITING` for basic functionality
- [ ] Write unit test `TestTokenBucketRefill_REQ_RATE_LIMITING` for refill logic
- [ ] Write unit test `TestTokenBucketExhausted_REQ_RATE_LIMITING` for limit exceeded

**P0: Implement rate limiting middleware [REQ:RATE_LIMITING]**
- [ ] Create middleware function signature matching existing middleware pattern
- [ ] Extract API key from request
- [ ] Extract endpoint path from request
- [ ] Integrate token bucket check
- [ ] Return 429 response with Retry-After header when limit exceeded
- [ ] Write integration test `TestRateLimitMiddleware_REQ_RATE_LIMITING`

**P0: Write unit tests for token bucket [REQ:RATE_LIMITING]**
- [ ] Test token consumption
- [ ] Test token refill with different rates
- [ ] Test bucket exhaustion
- [ ] Test concurrent access (if applicable)

**P1: Integrate Redis storage [REQ:RATE_LIMITING]**
- [ ] Create Redis client wrapper for rate limiting
- [ ] Implement `GetBucketState(key)` function
- [ ] Implement `SetBucketState(key, state, ttl)` function
- [ ] Implement Redis key naming strategy
- [ ] Write integration test `TestRedisStorage_REQ_RATE_LIMITING`

**P1: Add configuration support [REQ:RATE_LIMITING]**
- [ ] Extend config struct with rate limit settings
- [ ] Add default rate limit values
- [ ] Add per-endpoint override structure
- [ ] Implement config loading and parsing
- [ ] Write test `TestConfigLoading_REQ_RATE_LIMITING`

**P1: Implement admin key exemption [REQ:RATE_LIMITING]**
- [ ] Create function `IsAdminKey(apiKey)` to check admin keys
- [ ] Load admin keys from configuration
- [ ] Add exemption check in middleware before rate limit check
- [ ] Write test `TestAdminKeyExemption_REQ_RATE_LIMITING`

**P1: Write integration tests [REQ:RATE_LIMITING]**
- [ ] Test rate limiting with real Redis
- [ ] Test HTTP 429 response format
- [ ] Test Retry-After header calculation
- [ ] Test admin key bypass
- [ ] Test per-endpoint limits

**P2: Add metrics and logging [REQ:RATE_LIMITING]**
- [ ] Integrate with existing metrics system
- [ ] Add metric for rate limit exceeded events
- [ ] Add logging for rate limit events
- [ ] Write test `TestMetrics_REQ_RATE_LIMITING`

**P2: Add per-endpoint configuration [REQ:RATE_LIMITING]**
- [ ] Implement endpoint path matching logic
- [ ] Implement config lookup with endpoint override
- [ ] Write test `TestPerEndpointConfig_REQ_RATE_LIMITING`

All subtasks are now documented. Ready to proceed to Phase 3 (implementation)?

---

**Developer**: "Yes, let's start implementing. Begin with the P0 tasks."

---

### 💻 Phase 3: Tasks → Implementation

**AI**: "Observing AI principles!"

Starting with P0 tasks, beginning with the token bucket algorithm core logic.

**AI** (implementing):

Implementing the first subtask: Creating the `TokenBucket` struct.

**AI** (after completing subtask):

✅ Completed: Created `TokenBucket` struct with fields: tokens, lastRefill, limit, refillRate

Moving to next subtask: Implement `NewTokenBucket()` constructor.

**AI** (continuing implementation):

✅ Completed: Implemented `NewTokenBucket(limit, refillRate)` constructor  
✅ Completed: Implemented `AllowRequest()` method  
✅ Completed: Implemented `RefillTokens()` method  
✅ Completed: Wrote unit test `TestTokenBucket_REQ_RATE_LIMITING`  
✅ Completed: Wrote unit test `TestTokenBucketRefill_REQ_RATE_LIMITING`  
✅ Completed: Wrote unit test `TestTokenBucketExhausted_REQ_RATE_LIMITING`

All subtasks for "Implement token bucket algorithm core logic" are complete. Removing subtasks and marking parent task complete.

**AI** (updating tasks.md):

✅ Marked "Implement token bucket algorithm core logic" as complete

Starting next P0 task: "Implement rate limiting middleware"

**AI** (implementing middleware):

✅ Completed: Created middleware function signature  
✅ Completed: Extracted API key from request  
✅ Completed: Extracted endpoint path from request  
✅ Completed: Integrated token bucket check  
✅ Completed: Return 429 response with Retry-After header  
✅ Completed: Wrote integration test `TestRateLimitMiddleware_REQ_RATE_LIMITING`

**AI** (updating tasks.md):

✅ Marked "Implement rate limiting middleware" as complete

All P0 tasks complete. Moving to P1 tasks.

**AI** (continuing with P1 tasks):

Starting P1: "Integrate Redis storage"

**AI** (implementing Redis integration):

✅ Completed: Created Redis client wrapper  
✅ Completed: Implemented `GetBucketState(key)`  
✅ Completed: Implemented `SetBucketState(key, state, ttl)`  
✅ Completed: Implemented Redis key naming strategy  
✅ Completed: Wrote integration test `TestRedisStorage_REQ_RATE_LIMITING`

**AI** (updating tasks.md):

✅ Marked "Integrate Redis storage" as complete

Continuing with remaining P1 tasks...

**AI** (after completing all P1 tasks):

✅ All P1 tasks complete

**AI** (updating documentation):

Updating `requirements.md`:
- Marked `[REQ:RATE_LIMITING]` as ✅ Implemented

Updating `semantic-tokens.md`:
- Updated all token statuses to Implemented

All implementation complete! Should I proceed with P2 tasks (metrics and per-endpoint config), or would you like to test what we have first?

---

**Developer**: "Let's test what we have first. Run the tests and make sure everything passes."

---

**AI**: "Observing AI principles!"

Running all tests related to rate limiting:

**AI** (running tests):

```bash
go test -v -run "REQ_RATE_LIMITING" ./...
```

Test results:
- ✅ `TestTokenBucket_REQ_RATE_LIMITING` - PASSED
- ✅ `TestTokenBucketRefill_REQ_RATE_LIMITING` - PASSED
- ✅ `TestTokenBucketExhausted_REQ_RATE_LIMITING` - PASSED
- ✅ `TestRateLimitMiddleware_REQ_RATE_LIMITING` - PASSED
- ✅ `TestRedisStorage_REQ_RATE_LIMITING` - PASSED
- ✅ `TestConfigLoading_REQ_RATE_LIMITING` - PASSED
- ✅ `TestAdminKeyExemption_REQ_RATE_LIMITING` - PASSED

All tests passing! ✅

**AI** (final documentation update):

Updated `tasks.md`:
- All completed tasks marked as ✅ Complete
- All subtasks removed from completed tasks

The rate limiting feature is implemented and tested. P2 tasks (metrics and per-endpoint config) remain as optional enhancements.

---

## Key Takeaways from This Conversation

1. **AI Always Acknowledges Principles**: Every response starts with "Observing AI principles!"

2. **No Code Until Planning Complete**: Phase 1 (Requirements → Pseudo-Code) happens entirely without code changes

3. **Documentation Happens Immediately**: Architecture and implementation decisions are documented as they're made, not deferred

4. **Requirements Include Satisfaction & Validation**: Each requirement has explicit criteria for both satisfaction and validation

5. **Tasks Have Priorities**: All tasks are assigned P0/P1/P2/P3 priorities

6. **Subtasks Are Temporary**: Subtasks are removed when parent tasks complete

7. **Semantic Tokens Throughout**: Every decision, test, and code comment references semantic tokens

8. **Traceability Maintained**: Requirements → Architecture → Implementation → Tests → Code all linked via tokens

9. **Developer Can Review Before Implementation**: Planning phase allows review before any code is written

10. **Iterative Refinement**: Requirements can be refined based on developer feedback before implementation

---

## Conversation Patterns

### Pattern 1: Initial Feature Request
- Developer describes need
- AI acknowledges principles
- AI asks clarifying questions
- Developer provides answers

### Pattern 2: Planning Phase
- AI documents requirements with satisfaction/validation criteria
- AI documents architecture decisions
- AI documents implementation decisions
- AI creates tasks
- AI provides pseudo-code
- Developer reviews and approves

### Pattern 3: Refinement
- Developer requests changes/clarifications
- AI updates documentation immediately
- Developer approves
- Proceed to next phase

### Pattern 4: Implementation Phase
- AI implements highest priority tasks first
- AI updates tasks.md as subtasks complete
- AI removes completed subtasks
- AI marks parent tasks complete when all subtasks done
- AI updates documentation throughout

### Pattern 5: Completion
- AI runs tests
- AI verifies all documentation is current
- AI marks requirements as implemented
- AI updates token registry
- Developer reviews and approves

---

## Notes for Developers

When working with AI following STDD:

1. **Be Specific**: Provide clear requirements and answer clarifying questions
2. **Review Planning**: Take time to review Phase 1 documentation before approving
3. **Request Changes Early**: It's easier to change documentation than code
4. **Trust the Process**: The documentation-first approach prevents rework
5. **Verify Traceability**: Check that semantic tokens are used consistently

---

## Notes for AI Agents

When following STDD:

1. **Always Acknowledge**: Start every response with "Observing AI principles!"
2. **No Code in Phase 1**: Planning phase is documentation only
3. **Document Immediately**: Don't defer documentation - do it as decisions are made
4. **Ask Questions**: Clarify requirements before documenting
5. **Show Pseudo-Code**: Help developer visualize the approach
6. **Update Tasks Continuously**: Keep tasks.md current as work progresses
7. **Remove Subtasks**: Clean up completed subtasks
8. **Maintain Tokens**: Keep semantic-tokens.md updated
9. **Cross-Reference**: Always link tokens: IMPL → ARCH → REQ
10. **Test References**: Include semantic tokens in test names

---

**End of Conversation Template**

