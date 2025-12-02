Please also reference the following documents as needed:

@.claude/memories/personas.md description: "SuperClaude persona activation guidelines" globs: "**/*"
@.claude/memories/standards.md description: "Universal TypeScript coding standards" globs: "**/*.ts,**/*.tsx,**/*.js,**/*.jsx"

# Global Development Standards

## Core Principles

- **Improvement Mandate**: Never downgrade, bypass or duplicate. Improve, fix, clean.
- **DRY**: Don't Repeat Yourself - eliminate redundancy, consolidate duplicated code.
- **KISS**: Keep It Simple, Stupid - favor simple, clear solutions.
- **YAGNI**: You Aren't Gonna Need It - no speculative features.
- **Edit Over Create**: Always edit existing files instead of creating new versions.
- **Modern Only**: Always use the most current, recommended approaches.

## Restrictions

- Never implement fallback mechanisms or backwards compatibility layers
- Never create files with "enhanced-", "-fixed", "-new", "-v2", "-copy" patterns
- Never create .md files unless expressly instructed
- No console.log in production code; use logger
- No commented-out code; delete or create an issue

---

## Naming Conventions

### Files & Folders
- **PascalCase** for classes/types: `UserService.ts`, `IUserRepository.ts`
- **camelCase** for functions/utilities: `getUserById`, `formatDate`
- **kebab-case** for folders: `user-service/`, `auth-repository/`
- **Match file name to main export**: `UserService.ts` exports `UserService`
- **Interfaces start with `I`**: `IUserRepository`

### Service & Repository Naming
- **Type-first hierarchical**: `<Type><Role>` in PascalCase
- Examples: `UserService`, `UserRepository`, `AuthMiddleware`, `PaymentAdapter`

### Variables & Functions
- Expressive intent: `fetchUserByEmail` not `query1`
- Boolean prefixes: `isValid`, `hasError`, `canAccess`, `shouldRetry`
- Event handlers: `onUserCreated`, `handlePaymentError`
- Private members: `_internalState` or `#privateField`

### Types & Interfaces
- **DTO**: `CreateUserDTO`, `UpdateUserDTO`, `UserResponseDTO`
- **Entity**: `User`, `Product`, `Order`
- **Request/Response**: `CreateUserRequest`, `UserListResponse`
- **Enum**: `UserRole`, `OrderStatus` (PascalCase)

### Constants
- **SCREAMING_SNAKE_CASE**: `MAX_RETRY_ATTEMPTS`, `DEFAULT_TIMEOUT`

---

## Code Quality Standards

### Type Safety
- TypeScript **strict mode** enabled
- No `any` types; use `unknown` and narrow down
- All function parameters must have **explicit types**
- All function return types must be **explicit**
- Use discriminated unions for complex types

### Async/Await
- Always use `async/await`, never `.then()` chains
- Use `try/catch` for error handling
- Never swallow errors; log or re-throw
- Use `Promise.all()` for parallel operations
- Use `Promise.allSettled()` for independent operations

### Error Handling
- Create **custom error classes** extending `Error`
- Include error codes and HTTP status codes
- Always provide meaningful error messages
- Never expose internal implementation details

### Testing
- Every service/repository must have **unit tests**
- Every public API endpoint must have **integration tests**
- Test coverage minimum: **80%** for critical business logic
- Test files: `*.test.ts` or `*.spec.ts`

### Logging
- Use **structured logging** (JSON format)
- Include **request ID** for tracing
- Log levels: `debug`, `info`, `warn`, `error`
- Never log sensitive data (passwords, tokens, PII)

### Git Workflow
- Feature branches: `feat/feature-name`
- Bugfix branches: `fix/bug-name`
- **Conventional Commits**: `feat(auth): add jwt validation`
- Never commit to `main` directly; use PRs

---

## Architectural Principles

### Design Principles
- **SOLID**: Single Responsibility, Open/Closed, Liskov, Interface Segregation, Dependency Inversion
- **Feature/domain-based organization**: Each domain owns services, types, tests
- **Shallow folder hierarchies**: 2-3 levels max
- **Inward dependencies**: Depend on abstractions, not implementations

### Dependency Injection
- Use **constructor injection** for loose coupling
- Never use global singletons for services
- Abstract dependencies behind interfaces (`IUserRepository`)

---

## Common Patterns

### Service Pattern
```typescript
export interface IUserService {
  findById(id: string): Promise<User | null>;
  create(dto: CreateUserDTO): Promise<User>;
}

export class UserService implements IUserService {
  constructor(private repository: IUserRepository) {}

  async findById(id: string): Promise<User | null> {
    return this.repository.findById(id);
  }
}
```

### Repository Pattern
```typescript
export interface IUserRepository {
  findById(id: string): Promise<User | null>;
  create(dto: CreateUserDTO): Promise<User>;
}

export class UserRepository implements IUserRepository {
  async findById(id: string): Promise<User | null> {
    return db.user.findUnique({ where: { id } });
  }
}
```

### Error Handling Pattern
```typescript
export class ServiceError extends Error {
  constructor(
    public code: string,
    public statusCode: number,
    message: string,
    public details?: Record<string, unknown>
  ) {
    super(message);
    this.name = 'ServiceError';
  }
}
```

---

## Folder Structure

```
src/
├── features/           # Feature/domain-based
│   ├── auth/
│   │   ├── services/
│   │   ├── repositories/
│   │   ├── types/
│   │   └── dto/
│   └── users/
├── shared/             # Cross-cutting concerns
│   ├── utils/
│   ├── types/
│   ├── constants/
│   └── errors/
├── lib/                # Third-party integrations
├── middleware/
├── config/
└── main.ts
tests/
├── unit/
├── integration/
└── fixtures/
```
