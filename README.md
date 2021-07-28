# qpt-compact

## Description and use
This is a command line tool for compress and decompress, files and folders.
Use a lossless compression.
> Type `compactor -h` or `--help`

## Executable
Download the executable for [windows](https://clck.ru/WTfQz) **version 1.0.0**.

## Development
This tool is written in [dart](https://dart.dev) with help of the package manager, [pub](https://pub.dev), of dart for donwload the necesary libraries for the app.
For compressing the files and folder I use the [bzip2 encoder](https://en.wikipedia.org/wiki/Bzip2).

I save the info in a header in json string, the structure of this is a tree, the folder object have a list of childs that can be other folder or a file, the file object will save her location of content of her in a [base64](https://en.wikipedia.org/wiki/Base64) string with a constant length of 24 characters that indicates the byteoffset and the length.

For read the file, at the beginning of the file you will find a binary unsinged int of 64 bit that indicate the length of the json header, for the location of the file divide the string in two, parse to byteArray and to Uint64, then you have two numbers left, the first indicate the byteoffset and the other the length of file.