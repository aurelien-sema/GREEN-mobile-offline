import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Force all Kotlin compilation tasks to target JVM 17.
// Then override file_picker, flutter_onnxruntime and tflite_flutter to target JVM 11 to match their Java configs.
subprojects {
    tasks.withType<KotlinCompile>().configureEach {
        val projectName = project.name
        val targetJvm = when {
            projectName.startsWith("file_picker") ||
                projectName.startsWith("flutteronnxruntime") ||
                projectName.startsWith("flutter_onnxruntime") ||
                projectName.startsWith("tflite_flutter") -> JvmTarget.JVM_11
            else -> JvmTarget.JVM_17
        }
        compilerOptions {
            jvmTarget.set(targetJvm)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
