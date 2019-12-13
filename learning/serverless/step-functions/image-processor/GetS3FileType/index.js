exports.handler = async (event) => {
    let filename = event.s3.object.key;
    let index = filename.lastIndexOf('.');
    if (index > 0)
        return filename.substring(index + 1);
    else
        return null;
};
