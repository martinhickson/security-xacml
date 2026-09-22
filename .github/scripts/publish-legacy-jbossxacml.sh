#!/usr/bin/env bash
# Publish the upstream LGPL jbossxacml 2.0.8.Final jar (the coordinate PicketBox
# compiles against) under io.github.martinhickson so the full PicketBox reactor
# can go to Maven Central. The 2.1.8 sources in this repo are a different artifact.
set -euo pipefail

GROUP_ID="${1:-io.github.martinhickson}"
VERSION="2.0.8.Final"
BASE="https://repository.jboss.org/nexus/repository/public/org/jboss/security/jbossxacml/${VERSION}"
WORKDIR="$(mktemp -d)"
cd "${WORKDIR}"

curl -fsSL -o upstream.jar "${BASE}/jbossxacml-${VERSION}.jar"
curl -fsSL -o upstream-sources.jar "${BASE}/jbossxacml-${VERSION}-sources.jar"
mkdir -p src/main/java
unzip -q -o upstream-sources.jar -d src/main/java

cat > pom.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  <groupId>${GROUP_ID}</groupId>
  <artifactId>jbossxacml</artifactId>
  <version>${VERSION}</version>
  <packaging>jar</packaging>
  <name>JBoss XACML</name>
  <description>JBoss XACML ${VERSION}, republished under ${GROUP_ID}. Upstream license is LGPL.</description>
  <url>https://github.com/martinhickson/security-xacml</url>
  <licenses>
    <license>
      <name>GNU Lesser General Public License v2.1 only</name>
      <url>https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html</url>
      <distribution>repo</distribution>
    </license>
  </licenses>
  <developers>
    <developer>
      <name>JBoss</name>
      <organization>JBoss</organization>
      <organizationUrl>https://www.jboss.org</organizationUrl>
    </developer>
  </developers>
  <scm>
    <connection>scm:git:https://github.com/martinhickson/security-xacml.git</connection>
    <developerConnection>scm:git:ssh://git@github.com/martinhickson/security-xacml.git</developerConnection>
    <url>https://github.com/martinhickson/security-xacml</url>
    <tag>2.1.8.jakarta.bravura.11</tag>
  </scm>
  <properties>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <maven.compiler.release>8</maven.compiler.release>
  </properties>
  <build>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-compiler-plugin</artifactId>
        <version>3.13.0</version>
        <configuration>
          <skip>true</skip>
        </configuration>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-antrun-plugin</artifactId>
        <version>3.1.0</version>
        <executions>
          <execution>
            <phase>process-classes</phase>
            <goals><goal>run</goal></goals>
            <configuration>
              <target>
                <unzip src="\${project.basedir}/upstream.jar" dest="\${project.build.outputDirectory}" overwrite="true"/>
              </target>
            </configuration>
          </execution>
        </executions>
      </plugin>
      <plugin>
        <groupId>org.sonatype.central</groupId>
        <artifactId>central-publishing-maven-plugin</artifactId>
        <version>0.7.0</version>
        <extensions>true</extensions>
        <configuration>
          <publishingServerId>central</publishingServerId>
          <autoPublish>true</autoPublish>
          <waitUntil>published</waitUntil>
        </configuration>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-source-plugin</artifactId>
        <version>3.3.1</version>
        <executions>
          <execution>
            <id>attach-sources</id>
            <goals><goal>jar-no-fork</goal></goals>
          </execution>
        </executions>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-javadoc-plugin</artifactId>
        <version>3.11.2</version>
        <configuration>
          <doclint>none</doclint>
          <failOnError>false</failOnError>
          <failOnWarnings>false</failOnWarnings>
          <source>8</source>
        </configuration>
        <executions>
          <execution>
            <id>attach-javadocs</id>
            <goals><goal>jar</goal></goals>
          </execution>
        </executions>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-gpg-plugin</artifactId>
        <version>3.2.7</version>
        <executions>
          <execution>
            <id>sign-artifacts</id>
            <phase>verify</phase>
            <goals><goal>sign</goal></goals>
            <configuration>
              <gpgArguments>
                <arg>--pinentry-mode</arg>
                <arg>loopback</arg>
              </gpgArguments>
            </configuration>
          </execution>
        </executions>
      </plugin>
    </plugins>
  </build>
  <distributionManagement>
    <repository>
      <id>central</id>
      <url>https://central.sonatype.com/</url>
    </repository>
  </distributionManagement>
</project>
EOF

mvn -B -ntp deploy -DskipTests -Dgpg.passphrase="${MAVEN_CENTRAL_GPG_PASSPHRASE:-}"
echo "Published ${GROUP_ID}:jbossxacml:${VERSION}"
