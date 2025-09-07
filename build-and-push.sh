#!/bin/bash

# Placeholder Page - Cross Platform Build and Push Script
# This script builds and pushes the place-holder-page Docker image for multiple architectures

set -e  # Exit on any error

# Configuration
IMAGE_NAME="hazelgallery/place-holder-page"
BUILDER_NAME="multiplatform"
PLATFORMS="linux/amd64,linux/arm64"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is running
check_docker() {
    print_status "Checking Docker status..."
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_success "Docker is running"
}

# Function to check if buildx is available
check_buildx() {
    print_status "Checking Docker buildx availability..."
    if ! docker buildx version >/dev/null 2>&1; then
        print_error "Docker buildx is not available. Please update Docker to a newer version."
        exit 1
    fi
    print_success "Docker buildx is available"
}

# Function to setup multi-platform builder
setup_builder() {
    print_status "Setting up multi-platform builder..."
    
    # Check if builder already exists
    if docker buildx inspect $BUILDER_NAME >/dev/null 2>&1; then
        print_warning "Builder '$BUILDER_NAME' already exists, using existing builder"
    else
        print_status "Creating new builder '$BUILDER_NAME'..."
        docker buildx create --name $BUILDER_NAME --use
        print_success "Created builder '$BUILDER_NAME'"
    fi
    
    # Use the builder
    docker buildx use $BUILDER_NAME
    print_success "Using builder '$BUILDER_NAME'"
    
    # Bootstrap the builder (this may take a moment)
    print_status "Bootstrapping builder (this may take a moment)..."
    docker buildx inspect --bootstrap
    print_success "Builder ready"
}

# Function to build and push the image
build_and_push() {
    print_status "Building and pushing multi-platform image..."
    print_status "Image: $IMAGE_NAME"
    print_status "Platforms: $PLATFORMS"
    
    # Build and push for multiple platforms
    docker buildx build \
        --platform $PLATFORMS \
        -t $IMAGE_NAME:latest \
        --push \
        .
    
    print_success "Multi-platform image built and pushed successfully!"
}

# Function to test the image
test_image() {
    print_status "Testing the pushed image..."
    
    # Pull the image to verify it's available
    docker pull $IMAGE_NAME:latest
    print_success "Image pulled successfully"
    
    # Test run (will be cleaned up)
    print_status "Running test container..."
    TEST_CONTAINER=$(docker run -d -p 8510:80 \
        -e PORT=8510 \
        $IMAGE_NAME:latest)
    
    # Wait a moment for container to start
    sleep 3
    
    # Check if container is running
    if docker ps --filter "id=$TEST_CONTAINER" --format "table {{.ID}}" | grep -q $TEST_CONTAINER; then
        print_success "Test container is running successfully!"
        print_status "Test URL: http://localhost:8510"
        
        # Clean up test container
        print_status "Cleaning up test container..."
        docker stop $TEST_CONTAINER >/dev/null
        docker rm $TEST_CONTAINER >/dev/null
        print_success "Test container cleaned up"
    else
        print_error "Test container failed to start"
        # Show logs for debugging
        docker logs $TEST_CONTAINER
        docker rm $TEST_CONTAINER >/dev/null 2>&1
        exit 1
    fi
}

# Function to show usage information
show_usage() {
    echo "Placeholder Page - Cross Platform Build Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -t, --test     Run test after build and push"
    echo "  --no-push      Build only, don't push to Docker Hub"
    echo "  --cleanup      Remove builder after build"
    echo ""
    echo "Examples:"
    echo "  $0              # Build and push"
    echo "  $0 --test       # Build, push, and test"
    echo "  $0 --no-push    # Build only (local)"
    echo ""
}

# Main script
main() {
    local runTest=false
    local pushImage=true
    local cleanupBuilder=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -t|--test)
                runTest=true
                shift
                ;;
            --no-push)
                pushImage=false
                shift
                ;;
            --cleanup)
                cleanupBuilder=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    echo "========================================"
    echo "Placeholder Page - Multi-Platform Build"
    echo "========================================"
    echo ""
    
    # Check prerequisites
    check_docker
    check_buildx
    
    # Setup builder
    setup_builder
    
    # Build and optionally push
    if [ "$pushImage" = true ]; then
        build_and_push
        
        # Test if requested
        if [ "$runTest" = true ]; then
            test_image
        fi
        
        print_success "Build and push completed successfully!"
        print_status "Image is available at: docker.io/$IMAGE_NAME:latest"
        print_status "Supports platforms: $PLATFORMS"
    else
        print_status "Building for local use only (no push)..."
        docker buildx build \
            --platform $PLATFORMS \
            -t $IMAGE_NAME:latest \
            .
        print_success "Local build completed successfully!"
    fi
    
    # Cleanup builder if requested
    if [ "$cleanupBuilder" = true ]; then
        print_status "Cleaning up builder..."
        docker buildx rm $BUILDER_NAME
        print_success "Builder cleaned up"
    fi
    
    echo ""
    echo "========================================"
    print_success "All operations completed successfully!"
    echo "========================================"
}

# Run main function with all arguments
main "$@"
