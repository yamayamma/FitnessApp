# FitnessApp - Development Guide

This guide covers the development tooling and workflows for the FitnessApp project.

## 🛠 Development Tools

This project uses the following tools to maintain code quality and consistency:

- **SwiftLint**: Static code analysis to enforce Swift style and conventions
- **SwiftFormat**: Automatic code formatting
- **GitHub Actions**: Continuous Integration (CI) for automated testing
- **Git Hooks**: Pre-commit checks to catch issues before they're committed

## 📦 Installation

### Prerequisites

- macOS 13.0 or later
- Xcode 15.0 or later
- [Homebrew](https://brew.sh/) package manager

### Install Development Tools

```bash
# Install Swift tools using Brewfile
brew bundle

# Install xcpretty (Ruby gem for formatting xcodebuild output)
gem install xcpretty

# Or install individually
brew install swiftlint
brew install swiftformat
gem install xcpretty
```

### Setup Git Hooks

```bash
# Run the setup script to configure git hooks
./setup-git-hooks.sh
```

This will configure git to use the hooks in `.githooks/` directory, which includes:
- **pre-commit**: Runs SwiftFormat and SwiftLint on staged files before committing

## 🔍 Using the Tools

### SwiftLint

```bash
# Lint all Swift files
swiftlint

# Lint with strict mode (treats warnings as errors)
swiftlint lint --strict

# Auto-fix issues where possible
swiftlint --fix

# Lint specific files
swiftlint lint --path FitnessApp/
```

Configuration: `.swiftlint.yml`

### SwiftFormat

```bash
# Format all Swift files
swiftformat .

# Check formatting without making changes
swiftformat --lint .

# Format specific directory
swiftformat FitnessApp/

# Format specific file
swiftformat FitnessApp/FitnessAppApp.swift
```

Configuration: `.swiftformat`

### Running Tests Locally

```bash
# iOS Unit Tests
xcodebuild test \
  -project FitnessApp.xcodeproj \
  -scheme FitnessApp \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:FitnessAppTests

# iOS UI Tests
xcodebuild test \
  -project FitnessApp.xcodeproj \
  -scheme FitnessApp \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:FitnessAppUITests

# watchOS Unit Tests
xcodebuild test \
  -project FitnessApp.xcodeproj \
  -scheme "FitnessAppWatch Watch App" \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' \
  -only-testing:"FitnessAppWatch Watch AppTests"
```

## 🔄 Development Workflow

### 1. Before Starting Work

```bash
# Make sure you're on the latest main branch
git checkout main
git pull origin main

# Create a feature branch
git checkout -b feature/your-feature-name
```

### 2. During Development

- Write your code following the existing style
- The pre-commit hook will automatically check your code when you commit
- If the hook fails, fix the issues and try committing again

```bash
# Stage your changes
git add .

# Commit (pre-commit hook runs automatically)
git commit -m "Add: your feature description"

# If hook fails, fix issues and commit again
swiftformat .
swiftlint --fix
git add .
git commit -m "Add: your feature description"
```

### 3. Before Creating a Pull Request

```bash
# Run all checks locally
swiftlint lint --strict
swiftformat --lint .

# Make sure tests pass
# Run tests using Xcode or xcodebuild commands above
```

### 4. Creating a Pull Request

1. Push your branch to GitHub
2. Create a Pull Request targeting `main` branch
3. GitHub Actions will automatically run:
   - SwiftLint checks
   - SwiftFormat validation
   - iOS unit tests
   - iOS UI tests
   - watchOS unit tests
4. All checks must pass before merging

## 🤖 Continuous Integration (CI)

### GitHub Actions Workflow

The CI pipeline runs automatically on:
- Every push to `main` branch
- Every pull request to `main` or `develop` branches

**Jobs:**
1. **Lint & Format Check**: Validates code style and formatting
2. **Test iOS App**: Builds and tests iOS app (unit + UI tests)
3. **Test watchOS App**: Builds and tests watchOS app
4. **All Tests Passed**: Summary job that ensures all checks passed

Configuration: `.github/workflows/ci.yml`

### CI Status Badges

You can add CI status badges to your README:

```markdown
![CI Status](https://github.com/yamayamma/FitnessApp/workflows/CI/badge.svg)
```

## 📝 Configuration Files

- `.swiftlint.yml`: SwiftLint rules and settings
- `.swiftformat`: SwiftFormat rules and settings
- `.github/workflows/ci.yml`: GitHub Actions CI configuration
- `.githooks/pre-commit`: Pre-commit hook script
- `Brewfile`: Development tool dependencies
- `setup-git-hooks.sh`: Git hooks setup script

## 🐛 Troubleshooting

### Pre-commit hook not running

```bash
# Re-run the setup script
./setup-git-hooks.sh

# Or manually configure git hooks path
git config core.hooksPath .githooks
```

### SwiftFormat/SwiftLint not found

```bash
# Reinstall tools
brew install swiftlint swiftformat

# Verify installation
which swiftlint
which swiftformat
```

### CI tests failing

1. Check the GitHub Actions logs for specific errors
2. Run the same tests locally using the xcodebuild commands
3. Make sure your code is formatted: `swiftformat .`
4. Make sure your code passes linting: `swiftlint lint --strict`

### Temporarily bypass pre-commit hook

```bash
# Only use in emergencies!
git commit --no-verify -m "Your message"
```

## 🎯 Code Quality Standards

### SwiftLint Rules

Key rules enforced:
- File length: max 500 lines (warning), 1000 lines (error)
- Function length: max 60 lines (warning), 100 lines (error)
- Type body length: max 300 lines (warning), 500 lines (error)
- Cyclomatic complexity: max 10 (warning), 20 (error)
- Force unwrapping: warning
- Force cast: warning
- No print statements: warning (use proper logging)

### SwiftFormat Settings

Key formatting rules:
- Indent: 4 spaces
- Max line width: 120 characters
- Self keyword: always explicit
- Sorted imports
- Redundant type inference enabled
- Empty collection literals using isEmpty

## 📚 Additional Resources

- [SwiftLint Documentation](https://realm.github.io/SwiftLint/)
- [SwiftFormat Documentation](https://github.com/nicklockwood/SwiftFormat)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Swift Style Guide](https://google.github.io/swift/)

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Follow the development workflow above
4. Ensure all CI checks pass
5. Submit a pull request

## 📄 License

See LICENSE file for details.
