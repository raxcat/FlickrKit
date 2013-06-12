//
//  FKFlickrPhotosSetPerms.h
//  FlickrKit
//
//  Generated by FKAPIBuilder on 12 Jun, 2013 at 17:19.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved. http://www.devedup.com
//
//  DO NOT MODIFY THIS FILE - IT IS MACHINE GENERATED


#import "FKFlickrAPIMethod.h"

typedef enum {
	FKFlickrPhotosSetPermsError_PhotoNotFound = 1,		 /* The photo id passed was not a valid photo id of a photo belonging to the calling user. */
	FKFlickrPhotosSetPermsError_RequiredArgumentsMissing = 2,		 /* Some or all of the required arguments were not supplied. */
	FKFlickrPhotosSetPermsError_InvalidSignature = 96,		 /* The passed signature was invalid. */
	FKFlickrPhotosSetPermsError_MissingSignature = 97,		 /* The call required signing but no signature was sent. */
	FKFlickrPhotosSetPermsError_LoginFailedOrInvalidAuthToken = 98,		 /* The login details or auth token passed were invalid. */
	FKFlickrPhotosSetPermsError_UserNotLoggedInOrInsufficientPermissions = 99,		 /* The method requires user authentication but the user was not logged in, or the authenticated method call did not have the required permissions. */
	FKFlickrPhotosSetPermsError_InvalidAPIKey = 100,		 /* The API key passed was not valid or has expired. */
	FKFlickrPhotosSetPermsError_ServiceCurrentlyUnavailable = 105,		 /* The requested service is temporarily unavailable. */
	FKFlickrPhotosSetPermsError_FormatXXXNotFound = 111,		 /* The requested response format was not found. */
	FKFlickrPhotosSetPermsError_MethodXXXNotFound = 112,		 /* The requested method was not found. */
	FKFlickrPhotosSetPermsError_InvalidSOAPEnvelope = 114,		 /* The SOAP envelope send in the request could not be parsed. */
	FKFlickrPhotosSetPermsError_InvalidXMLRPCMethodCall = 115,		 /* The XML-RPC request document could not be parsed. */
	FKFlickrPhotosSetPermsError_BadURLFound = 116,		 /* One or more arguments contained a URL that has been used for abuse on Flickr. */

} FKFlickrPhotosSetPermsError;

/*

Set permissions for a photo.


Response:

<photoid secret="abcdef" originalsecret="abcdef">1234</photoid>

*/
@interface FKFlickrPhotosSetPerms : NSObject <FKFlickrAPIMethod>

/* The id of the photo to set permissions for. */
@property (nonatomic, strong) NSString *photo_id; /* (Required) */

/* 1 to set the photo to public, 0 to set it to private. */
@property (nonatomic, strong) NSString *is_public; /* (Required) */

/* 1 to make the photo visible to friends when private, 0 to not. */
@property (nonatomic, strong) NSString *is_friend; /* (Required) */

/* 1 to make the photo visible to family when private, 0 to not. */
@property (nonatomic, strong) NSString *is_family; /* (Required) */

/* who can add comments to the photo and it's notes. one of:<br />
<code>0</code>: nobody<br />
<code>1</code>: friends &amp; family<br />
<code>2</code>: contacts<br />
<code>3</code>: everybody */
@property (nonatomic, strong) NSString *perm_comment; /* (Required) */

/* who can add notes and tags to the photo. one of:<br />
<code>0</code>: nobody / just the owner<br />
<code>1</code>: friends &amp; family<br />
<code>2</code>: contacts<br />
<code>3</code>: everybody
 */
@property (nonatomic, strong) NSString *perm_addmeta; /* (Required) */


@end
