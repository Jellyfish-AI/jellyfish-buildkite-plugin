#!/bin/bash

# Main test runner for Jellyfish Buildkite Plugin
# This script runs all tests from the root directory

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="$SCRIPT_DIR/tests"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

show_help() {
    echo "Jellyfish Buildkite Plugin Test Runner"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -q, --quick    Run quick local test only"
    echo "  -f, --full     Run full comprehensive test suite"
    echo "  -p, --payload  Test JSON payload generation only"
    echo "  -a, --all      Run all tests (default)"
    echo ""
    echo "Examples:"
    echo "  $0              # Run all tests"
    echo "  $0 --quick     # Run quick local test"
    echo "  $0 --full      # Run comprehensive test suite"
    echo ""
}

run_test() {
    local test_name="$1"
    local test_script="$2"
    
    echo -e "${BLUE}=== Running $test_name ===${NC}"
    echo ""
    
    if [ -f "$TESTS_DIR/$test_script" ]; then
        (cd "$TESTS_DIR" && ./"$test_script")
        local exit_code=$?
        echo ""
        return $exit_code
    else
        echo -e "${RED}❌ Test script not found: $test_script${NC}"
        return 1
    fi
}

# Default to running all tests
QUICK_ONLY=false
FULL_ONLY=false
PAYLOAD_ONLY=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -q|--quick)
            QUICK_ONLY=true
            shift
            ;;
        -f|--full)
            FULL_ONLY=true
            shift
            ;;
        -p|--payload)
            PAYLOAD_ONLY=true
            shift
            ;;
        -a|--all)
            # This is the default, so no need to set anything
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

echo -e "${GREEN}🧪 Jellyfish Buildkite Plugin Test Runner${NC}"
echo ""

# Check dependencies
echo "🔍 Checking dependencies..."
if ! command -v curl &> /dev/null; then
    echo -e "${RED}❌ curl is required but not installed${NC}"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ jq is required but not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Dependencies OK${NC}"
echo ""

# Run tests based on options
OVERALL_EXIT_CODE=0

if [ "$PAYLOAD_ONLY" = true ]; then
    run_test "JSON Payload Test" "test-payload.sh" || OVERALL_EXIT_CODE=1
elif [ "$QUICK_ONLY" = true ]; then
    run_test "Quick Local Test" "test-local.sh" || OVERALL_EXIT_CODE=1
elif [ "$FULL_ONLY" = true ]; then
    run_test "Comprehensive Test Suite" "test-suite.sh" || OVERALL_EXIT_CODE=1
else
    # Run all tests
    echo -e "${YELLOW}📋 Running all tests...${NC}"
    echo ""
    
    run_test "Quick Local Test" "test-local.sh" || OVERALL_EXIT_CODE=1
    run_test "JSON Payload Validation" "test-payload.sh" || OVERALL_EXIT_CODE=1
    run_test "Comprehensive Test Suite" "test-suite.sh" || OVERALL_EXIT_CODE=1
    
    if [ $OVERALL_EXIT_CODE -eq 0 ]; then
        echo -e "${GREEN}🎉 All test suites completed successfully!${NC}"
    else
        echo -e "${RED}❌ Some test suites failed${NC}"
    fi
fi

echo -e "${BLUE}💡 For more testing options, see tests/README.md${NC}"

exit $OVERALL_EXIT_CODE