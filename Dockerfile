# Force x86_64 to avoid gen_snapshot issues on Apple Silicon
FROM --platform=linux/amd64 eclipse-temurin:17-jdk

# Install essential tools
RUN apt-get update && apt-get install -y \
  curl unzip git xz-utils zip libglu1-mesa \
  && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME (Java is pre-installed by eclipse-temurin)
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH="$JAVA_HOME/bin:$PATH"

# Install Flutter SDK
RUN git clone --depth 1 -b 3.19.6 https://github.com/flutter/flutter.git /opt/flutter
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Precache Flutter artifacts
RUN flutter doctor && flutter precache

# Install Android SDK
RUN mkdir -p /opt/android-sdk/cmdline-tools \
  && curl -sSL https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip -o cmdline-tools.zip \
  && unzip cmdline-tools.zip -d /opt/android-sdk/cmdline-tools \
  && mv /opt/android-sdk/cmdline-tools/cmdline-tools /opt/android-sdk/cmdline-tools/latest \
  && rm cmdline-tools.zip

ENV ANDROID_HOME=/opt/android-sdk
ENV PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

# Install required SDK packages
RUN yes | sdkmanager --licenses && \
    sdkmanager \
    "platform-tools" \
    "platforms;android-34" \
    "build-tools;35.0.0-rc3"

# Install Gradle 7.5
RUN curl -sL https://services.gradle.org/distributions/gradle-7.5-bin.zip -o gradle.zip \
  && unzip gradle.zip -d /opt \
  && rm gradle.zip
ENV PATH="/opt/gradle-7.5/bin:$PATH"

# Set working directory to your app
WORKDIR /app

# Final health check
RUN flutter doctor -v