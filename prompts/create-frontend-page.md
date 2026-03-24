# Frontend Page Prompt

Use this prompt to create React frontend pages.

```
Create a React page at /frontend/[route] for [APP_NAME].

## Page Type
[List / Detail / Create / Dashboard / Settings]

## Data Source
- API: [APP_NAME].api.[method]
- Doctype: [DocType]
- Filters: [filter fields]

## Components
- AppLayout wrapper
- PageHeader with title and actions
- [Component1] for [purpose]
- [Component2] for [purpose]

## State
- Loading: spinner
- Error: ErrorBanner with retry
- Empty: empty state message
- Success: render data

## Actions
- [Action1]: [description]
- [Action2]: [description]

## Navigation
- From: /frontend/[from_route]
- To: /frontend/[to_route]

## Constraints
- Route under /frontend/*
- API calls to /api/*
- Use safeToFixed for numbers
- Handle null/undefined
```
