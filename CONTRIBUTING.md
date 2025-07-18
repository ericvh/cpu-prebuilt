# Contributing to CPU Prebuilt

Thank you for your interest in contributing to this project!

## How to Contribute

### Reporting Issues

If you encounter any issues with the built binaries or the build process:

1. Check existing [issues](../../issues) to see if it's already reported
2. If not, create a new issue with:
   - Clear description of the problem
   - Steps to reproduce
   - Expected vs actual behavior
   - Your system information (if relevant)

### Improving the Build Process

We welcome improvements to:

- **GitHub Actions workflow**: Make builds faster, more reliable, or support additional architectures
- **Documentation**: Improve README, build instructions, or usage examples
- **Build scripts**: Add features like checksums, signing, or additional validation

### Making Changes

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-improvement`
3. Make your changes
4. Test the workflow (you can trigger it manually in your fork)
5. Submit a pull request with:
   - Clear description of changes
   - Reasoning for the improvement
   - Test results if applicable

### Testing Changes

To test GitHub Actions changes:

1. Push to your fork
2. Go to the Actions tab in your fork
3. Manually trigger the "Build CPU Binaries" workflow
4. Verify the artifacts are created correctly
5. Download and test the binaries on an aarch64 system if possible

## Code of Conduct

Please be respectful and constructive in all interactions. This project follows the general open-source community standards for behavior.

## Questions?

Feel free to open an issue for questions about contributing or using this project.
