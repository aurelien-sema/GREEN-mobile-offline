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

// Chaque plugin compile son Kotlin pour la même JVM que sa partie Java
// (sinon Gradle refuse : "Inconsistent JVM-target compatibility"). Les
// plugins ne sont pas homogènes : tflite_flutter et flutter_onnxruntime
// ciblent Java 11, les autres Java 17. La cible est lue dans la
// configuration Android de chaque module au lieu d'une liste codée en dur.
subprojects {
    tasks.withType<KotlinCompile>().configureEach {
        val android = project.extensions.findByType(com.android.build.gradle.BaseExtension::class.java)
        // toString() donne "1.8" pour Java 8 (et non "8", refusé par Kotlin), "11", "17"…
        val target = android?.compileOptions?.targetCompatibility?.toString() ?: "17"
        compilerOptions {
            jvmTarget.set(JvmTarget.fromTarget(target))
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
