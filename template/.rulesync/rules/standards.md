---
root: false
targets: ["*"]
description: "Universal TypeScript coding standards"
globs: ["**/*.ts", "**/*.tsx", "**/*.js", "**/*.jsx"]
---

# Coding Standards

## Naming Conventions

### Files & Folders
- **PascalCase** for classes/types: `UserService.ts`, `IUserRepository.ts`
- **camelCase** for functions/utilities: `getUserById`, `formatDate`
- **kebab-case** for folders: `user-service/`, `auth-repository/`
- **Interfaces start with `I`**: `IUserRepository`

### Variables & Functions
- Expressive intent: `fetchUserByEmail` not `query1`
- Boolean prefixes: `isValid`, `hasError`, `canAccess`, `shouldRetry`
- Event handlers: `onUserCreated`, `handlePaymentError`

### Types
- **DTO**: `CreateUserDTO`, `UpdateUserDTO`
- **Entity**: `User`, `Product`, `Order`
- **Constants**: `SCREAMING_SNAKE_CASE`

## Code Quality

### Type Safety
- TypeScript **strict mode** enabled
- No `any` types; use `unknown` and narrow down
- All function parameters and return types must be **explicit**

### Async/Await
- Always use `async/await`, never `.then()` chains
- Use `try/catch` for error handling
- Never swallow errors; log or re-throw
- Use `Promise.all()` for parallel operations

### Error Handling
- Create **custom error classes** extending `Error`
- Include error codes and HTTP status codes
- Never expose internal implementation details

### Testing
- Every service/repository must have **unit tests**
- Test coverage minimum: **80%** for critical logic
- Test files: `*.test.ts` or `*.spec.ts`

### Logging
- Use **structured logging** (JSON format)
- Never log sensitive data (passwords, tokens, PII)
- No console.log in production; use logger

## Architecture

### Design Principles
- **SOLID**, **DRY**, **KISS**, **YAGNI**
- Feature/domain-based organization
- Shallow folder hierarchies: 2-3 levels max

### Dependency Injection
- Use **constructor injection**
- Abstract dependencies behind interfaces

## Git Workflow
- Feature branches: `feat/feature-name`
- Bugfix branches: `fix/bug-name`
- **Conventional Commits**: `feat(auth): add jwt validation`
