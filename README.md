# qpt-compact

## Description and use
This is a command line tool for compress and decompress, files and folders, using a lossless compression.
> Type `compactor -h` or `--help`

## Executable
Download the executable for [windows x64](https://github.com/Guillex387/qpt-compact/releases/download/1.1.0/compactor-win-v1.1.0-x64.zip) and [linux x64](https://github.com/Guillex387/qpt-compact/releases/download/1.1.0/compactor-linux-v1.1.0-x64.zip) **last version**.
> In linux for execute this, you need the executable permission, this command only needs to be used once.
>
> `$ chmod +x ./compactor`
>
> And then you can use the app.
>
> `$ ./compactor -h`

## Development
This tool is written in [dart](https://dart.dev) with help of the package manager [pub](https://pub.dev), for donwload the necesary libraries for the app.
For compressing the files and folders I use the [bzip2 encoder](https://en.wikipedia.org/wiki/Bzip2), in case that you don't like use the compressor put this flag `--no-compress`, you will find all commands structures in the help message.

I save the info in a json header, the structure of this is a tree, the folder object have a list of childs that can be a folder or a file, the file object will save her location of its content in a [base64](https://en.wikipedia.org/wiki/Base64) string with a constant length of 24 characters, that indicates the byteoffset and the length, and this header has a attribute called *compressed*, which is a boolean that indicates if the file contents have the bzip enconding or not.

For read the file, at the beginning you will find a binary unsinged int of 64 bit that indicate the length of the json header, for the location of the file, divide the string in two, parse to byteArray and to Uint64, then you have two numbers left, the first indicate the byteoffset and the other the length of file. Check if the contents of the files needs a bzip2 decoding with the *compressed* attribute of the header.

## License
Licensed under the [Apache License](https://github.com/Guillex387/qpt-compact/blob/master/LICENSE), Version 2.0. Copyright 2021 Guillex387