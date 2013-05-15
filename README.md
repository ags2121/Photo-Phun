Dephace
==========

An Instagram-like app that allows users to query the Flickr for photos, apply various Core Image filters to the images, and doodle on the filtered image.  

Implements the following features:

<ul>
<li> Photo querying service using the Flickr API.
<li> Caching Flickr responses NSCache.
<li> Scaling and resizing to display objects using the Core Image API. Uses Core Image face detection to center and resize photo when a face is detected.
<li> Seven distinct Image filters using CIFilter.
<li> Finger drawing on image using Core Image.
<li> Image saving to local app image library, with option to save to device photo library and/or post to Facebook wall.
<li> Attributed strings, appearance proxies, collection views, UIView animations, and PaperFoldMenuController custom control, utilized in design. PaperFoldMenu code taken from here: https://github.com/honcheng/PaperFold-for-iOS
</ul>
