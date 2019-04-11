```D


// The FileD type
//
struct FileD
{
    WriteResult tryWrite(void* ptr, size_t length);
    WriteResult tryWrite(void[] array);
}

auto result = filed.tryWrite(data);

/*
result.passed, returns true if all the data was successfully written
result.failed, returns true if all data was not written
result.onFailWritten, ONLY CALL IF failed IS TRUE
    returns the amount of data that was written
result.errorCode, returns the error code, only valid is failed is true
*/



```