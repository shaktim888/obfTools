#include <map>
#include "unzip.h"
#include "ZipLoader.h"
#include "Xor.h"
#include <string>
#include <vector>
#include <sys/stat.h>
// android doesn't have ftw.h
#if (CC_TARGET_PLATFORM != CC_PLATFORM_ANDROID)
#include <ftw.h>
#endif

#include <sys/types.h>
#include <errno.h>
#include <dirent.h>

namespace minizip
{
    #define UNZ_MAXFILENAMEINZIP 256

    static const std::string emptyFilename("");
    
    struct ZipEntryInfo
    {
        unz_file_pos pos;
        uLong uncompressed_size;
    };

    class ZipFilePrivate
    {
    public:
        unzFile zipFile;
        
        // std::unordered_map is faster if available on the platform
        typedef std::map<std::string, struct ZipEntryInfo> FileListContainer;
        FileListContainer fileList;
        bool setFilter(const std::string &filter);
    };

    class ZipFile
    {
    public:
        ZipFile();
        static ZipFile *createWithBuffer(const void* buffer, uLong size);
        std::string getFirstFilename();
        std::string getNextFilename();
        unsigned char *getFileData(const std::string &fileName, ssize_t *size);
    private:
        bool initWithBuffer(const void *buffer, uLong size);
        bool setFilter(const std::string &filter);
        int getCurrentFileInfo(std::string *filename, unz_file_info *info);
        ZipFilePrivate *_data;
    };

    ZipFile::ZipFile()
    : _data(new ZipFilePrivate)
    {
        _data->zipFile = nullptr;
    }

    ZipFile *ZipFile::createWithBuffer(const void* buffer, uLong size)
    {
        ZipFile *zip = new ZipFile();
        if (zip && zip->initWithBuffer(buffer, size)) {
            return zip;
        } else {
            if (zip) delete zip;
            return nullptr;
        }
    }


    bool ZipFile::initWithBuffer(const void *buffer, uLong size)
    {
        if (!buffer || size == 0) return false;
        
        _data->zipFile = minizip::unzOpenBuffer(buffer, size);
        if (!_data->zipFile) return false;
        
        setFilter(emptyFilename);
        return true;
    }


    bool ZipFile::setFilter(const std::string &filter)
    {
        bool ret = false;
        do
        {
            // clear existing file list
            _data->fileList.clear();
            
            // UNZ_MAXFILENAMEINZIP + 1 - it is done so in unzLocateFile
            char szCurrentFileName[UNZ_MAXFILENAMEINZIP + 1];
            unz_file_info64 fileInfo;
            
            // go through all files and store position information about the required files
            int err = unzGoToFirstFile64(_data->zipFile, &fileInfo,
                                         szCurrentFileName, sizeof(szCurrentFileName) - 1);
            while (err == UNZ_OK)
            {
                unz_file_pos posInfo;
                int posErr = unzGetFilePos(_data->zipFile, &posInfo);
                if (posErr == UNZ_OK)
                {
                    std::string currentFileName = szCurrentFileName;
                    // cache info about filtered files only (like 'assets/')
                    if (filter.empty()
                        || currentFileName.substr(0, filter.length()) == filter)
                    {
                        ZipEntryInfo entry;
                        entry.pos = posInfo;
                        entry.uncompressed_size = (uLong)fileInfo.uncompressed_size;
                        _data->fileList[currentFileName] = entry;
                    }
                }
                // next file - also get the information about it
                err = unzGoToNextFile64(_data->zipFile, &fileInfo,
                                        szCurrentFileName, sizeof(szCurrentFileName) - 1);
            }
            ret = true;
            
        } while(false);
        
        return ret;
    }

    std::string ZipFile::getFirstFilename()
    {
        if (unzGoToFirstFile(_data->zipFile) != UNZ_OK) return emptyFilename;
        std::string path;
        unz_file_info info;
        getCurrentFileInfo(&path, &info);
        return path;
    }

    std::string ZipFile::getNextFilename()
    {
        if (unzGoToNextFile(_data->zipFile) != UNZ_OK) return emptyFilename;
        std::string path;
        unz_file_info info;
        getCurrentFileInfo(&path, &info);
        return path;
    }
    
    unsigned char *ZipFile::getFileData(const std::string &fileName, ssize_t *size)
    {
        unsigned char * buffer = nullptr;
        if (size)
            *size = 0;

        do
        {
            auto it = _data->fileList.find(fileName);
            if(it ==  _data->fileList.end()) {
                throw "not found";
            }
            
            ZipEntryInfo fileInfo = it->second;
            
            int nRet = unzGoToFilePos(_data->zipFile, &fileInfo.pos);

            
            nRet = unzOpenCurrentFile(_data->zipFile);
            
            buffer = (unsigned char*)malloc(fileInfo.uncompressed_size);
            int nSize = unzReadCurrentFile(_data->zipFile, buffer, static_cast<unsigned int>(fileInfo.uncompressed_size));
            if(nSize != 0 && nSize != (int)fileInfo.uncompressed_size)
            {
                printf("the file size is wrong");
                return nullptr;
            }
            
            if (size)
            {
                *size = fileInfo.uncompressed_size;
            }
            unzCloseCurrentFile(_data->zipFile);
        } while (0);
        
        return buffer;
    }

    int ZipFile::getCurrentFileInfo(std::string *filename, unz_file_info *info)
    {
        char path[FILENAME_MAX + 1];
        int ret = unzGetCurrentFileInfo(_data->zipFile, info, path, sizeof(path), nullptr, 0, nullptr, 0);
        if (ret != UNZ_OK) {
            *filename = emptyFilename;
        } else {
            filename->assign(path);
        }
        return ret;
    }
}


bool isDirectoryExistInternal(const std::string& dirPath)
{
    struct stat st;
    if (stat(dirPath.c_str(), &st) == 0)
    {
        return S_ISDIR(st.st_mode);
    }
    return false;
}

static bool createDirectory(const std::string& path)
{

    if (isDirectoryExistInternal(path))
        return true;

    // Split the path
    size_t start = 0;
    size_t found = path.find_first_of("/\\", start);
    std::string subpath;
    std::vector<std::string> dirs;

    if (found != std::string::npos)
    {
        while (true)
        {
            subpath = path.substr(start, found - start + 1);
            if (!subpath.empty())
                dirs.push_back(subpath);
            start = found+1;
            found = path.find_first_of("/\\", start);
            if (found == std::string::npos)
            {
                if (start < path.length())
                {
                    dirs.push_back(path.substr(start));
                }
                break;
            }
        }
    }

    DIR *dir = NULL;

    // Create path recursively
    subpath = "";
    for (int i = 0; i < dirs.size(); ++i)
    {
        subpath += dirs[i];
        dir = opendir(subpath.c_str());

        if (!dir)
        {
            // directory doesn't exist, should create a new one

            int ret = mkdir(subpath.c_str(), S_IRWXU | S_IRWXG | S_IRWXO);
            if (ret != 0 && (errno != EEXIST))
            {
                // current directory can not be created, sub directories can not be created too
                // should return
                return false;
            }
        }
        else
        {
            // directory exists, should close opened dir
            closedir(dir);
        }
    }
    return true;
}


static void saveToFile(unsigned char * content, ssize_t size, std::string path)
{
    std::string directory;
    const size_t last_slash_idx = path.rfind('/');
    if (std::string::npos != last_slash_idx)
    {
        directory = path.substr(0, last_slash_idx);
    } else {
        const size_t last_slash_idx = path.rfind('\\');
        if (std::string::npos != last_slash_idx)
        {
            directory = path.substr(0, last_slash_idx);
        }
    }
    createDirectory(directory);
    FILE *fp = NULL; /* 需要注意 */
    fp = fopen(path.c_str(), "wb+");
    if (NULL == fp)
    {
        return; /* 要返回错误代码 */
    }
    fwrite(content, size, 1, fp);

    fclose(fp);
    fp = NULL; /* 需要指向空，否则会指向原打开文件地址 */
}


void loadZipFile(const char* zipFilePath,const char * saveTo)
{
    do {
        ssize_t size = 0;
        void *buffer = nullptr;
        unsigned char *zipFileData = Xor::getFileData(zipFilePath, "rb", &size);
        minizip::ZipFile *zip = nullptr;
        
        if (zipFileData) {
            zip = minizip::ZipFile::createWithBuffer(zipFileData, size);
        }
        
        if (zip) {
            int count = 0;
            std::string filename = zip->getFirstFilename();
            while (filename.length()) {
                ssize_t bufferSize = 0;
                unsigned char *zbuffer = zip->getFileData(filename.c_str(), &bufferSize);
                if (bufferSize) {
                    // save file to folder
                    saveToFile( zbuffer, bufferSize , std::string(saveTo) + "/" + filename);
                    count++;
                    free(zbuffer);
                } else {
                    createDirectory( std::string(saveTo) + "/" + filename);
                }
                filename = zip->getNextFilename();
            }
//            printf("lua_loadChunksFromZIP() - loaded chunks count: %d", count);
            // 解开完成
            delete zip;
        } else {
            printf("lua_loadChunksFromZIP() - not found or invalid zip file: %s", zipFilePath);
        }
        
        if (zipFileData) {
            free(zipFileData);
        }
        
        if (buffer) {
            free(buffer);
        }
    } while (0);
}

const char* getBundleWritableRoot() {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    std::string strRet = [documentsDirectory UTF8String];
    strRet.append("/");
    auto len = strRet.length();
    char * data = (char *)malloc((len + 1)*sizeof(char));
    strRet.copy(data,len,0);
    data[len] = '\0';
    return data;
}

const char* getBundleResRoot() {
    NSString *documentsDirectory = [[NSBundle mainBundle] resourcePath];
    std::string strRet = [documentsDirectory UTF8String];
    strRet.append("/");
    auto len = strRet.length();
    char * data = (char *)malloc((len + 1)*sizeof(char));
    strRet.copy(data,len,0);
    data[len] = '\0';
    return data;
}

short isBundleDirectoryExist(const char * path) {
    return isDirectoryExistInternal(path);
}
