// SPDX-License-Identifier: GPL-2.0-or-later

#include <jni.h>

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <memory>
#include <stdexcept>
#include <string>
#include <vector>

#include "DiscIO/DiscExtractor.h"
#include "DiscIO/Filesystem.h"
#include "DiscIO/Volume.h"

namespace
{
namespace fs = std::filesystem;

constexpr size_t BLOCK_SIZE = 1024 * 1024;

std::string GetString(JNIEnv* env, jstring value)
{
    if (!value)
        throw std::runtime_error("Argumento vacío");

    const char* chars = env->GetStringUTFChars(value, nullptr);

    if (!chars)
        throw std::runtime_error("No se pudo leer la cadena");

    std::string result(chars);
    env->ReleaseStringUTFChars(value, chars);
    return result;
}

jstring Result(JNIEnv* env, const std::string& message)
{
    return env->NewStringUTF(message.c_str());
}

DiscIO::Partition FindDataPartition(const DiscIO::Volume& volume)
{
    for (const auto& partition : volume.GetPartitions())
    {
        const auto type = volume.GetPartitionType(partition);

        if (type && *type == 0)
            return partition;
    }

    throw std::runtime_error("No se encontró la partición DATA");
}

void ExtractDirectory(
    const DiscIO::Volume& volume,
    const DiscIO::Partition& partition,
    const DiscIO::FileInfo& directory,
    const fs::path& destination,
    unsigned long long& extracted)
{
    fs::create_directories(destination);

    std::vector<unsigned char> buffer(BLOCK_SIZE);

    for (const auto& entry : directory)
    {
        const std::string name = entry.GetName();

        if (name.empty() || name == "." || name == ".." ||
            name.find('/') != std::string::npos ||
            name.find('\\') != std::string::npos ||
            name.find(':') != std::string::npos)
        {
            throw std::runtime_error("Nombre de archivo inválido");
        }

        const fs::path target = destination / name;

        if (entry.IsDirectory())
        {
            ExtractDirectory(
                volume, partition, entry, target, extracted);
            continue;
        }

        std::ofstream output(target, std::ios::binary);

        if (!output)
            throw std::runtime_error("No se pudo crear: " + name);

        const unsigned long long size = entry.GetSize();
        const unsigned long long offset = entry.GetOffset();

        unsigned long long position = 0;

        while (position < size)
        {
            const size_t amount = static_cast<size_t>(
                std::min<unsigned long long>(
                    BLOCK_SIZE, size - position));

            if (!volume.Read(
                    offset + position,
                    amount,
                    buffer.data(),
                    partition))
            {
                throw std::runtime_error("Error leyendo: " + name);
            }

            output.write(
                reinterpret_cast<const char*>(buffer.data()),
                static_cast<std::streamsize>(amount));

            if (!output)
                throw std::runtime_error("Error escribiendo: " + name);

            position += amount;
        }

        output.close();

        if (!output)
            throw std::runtime_error("Error cerrando: " + name);

        ++extracted;
    }
}
}

extern "C"
JNIEXPORT jstring JNICALL
Java_com_dolphintool_app_MainActivity_nativeInspect(
    JNIEnv* env, jobject, jstring inputPath)
{
    try
    {
        auto volume = DiscIO::CreateVolume(GetString(env, inputPath));

        if (!volume)
            return Result(env, "Error: no se pudo abrir la imagen");

        const auto partition = FindDataPartition(*volume);

        const auto* filesystem = volume->GetFileSystem(partition);

        if (!filesystem || !filesystem->IsValid())
            return Result(env, "DATA encontrada, pero el sistema de archivos no es válido");

        return Result(env, "Partición DATA encontrada. Sistema de archivos válido.");
    }
    catch (const std::exception& e)
    {
        return Result(env, std::string("Error: ") + e.what());
    }
}

extern "C"
JNIEXPORT jstring JNICALL
Java_com_dolphintool_app_MainActivity_nativeExtract(
    JNIEnv* env,
    jobject,
    jstring inputPath,
    jstring outputPath)
{
    try
    {
        const std::string source = GetString(env, inputPath);
        const std::string destination = GetString(env, outputPath);

        auto volume = DiscIO::CreateVolume(source);

        if (!volume)
            throw std::runtime_error("No se pudo abrir la imagen");

        const auto partition = FindDataPartition(*volume);

        const auto* filesystem = volume->GetFileSystem(partition);

        if (!filesystem || !filesystem->IsValid())
            throw std::runtime_error("Sistema de archivos DATA inválido");

        unsigned long long extracted = 0;

        const fs::path root(destination);
        fs::create_directories(root / "files");

        ExtractDirectory(
            *volume,
            partition,
            filesystem->GetRoot(),
            root / "files",
            extracted);

        if (!DiscIO::ExportSystemData(
                *volume, partition, root.string()))
        {
            throw std::runtime_error(
                "DATA extraída, pero falló la exportación "
                "de archivos de sistema");
        }

        return Result(
            env,
            "Extracción completada. Archivos: " +
            std::to_string(extracted));
    }
    catch (const std::exception& e)
    {
        return Result(env, std::string("Error: ") + e.what());
    }
}
