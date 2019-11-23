//
// Copyright 2010-2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

#import <Foundation/Foundation.h>
#import <AWSCore/AWSNetworking.h>
#import <AWSCore/AWSModel.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const AWSKinesisVideoSignalingErrorDomain;

typedef NS_ENUM(NSInteger, AWSKinesisVideoSignalingErrorType) {
    AWSKinesisVideoSignalingErrorUnknown,
    AWSKinesisVideoSignalingErrorClientLimitExceeded,
    AWSKinesisVideoSignalingErrorInvalidClient,
    AWSKinesisVideoSignalingErrorNotAuthorized,
    AWSKinesisVideoSignalingErrorResourceNotFound,
    AWSKinesisVideoSignalingErrorSessionExpired,
    AWSKinesisVideoSignalingErrorValidation,
};

typedef NS_ENUM(NSInteger, AWSKinesisVideoSignalingService) {
    AWSKinesisVideoSignalingServiceUnknown,
    AWSKinesisVideoSignalingServiceTurn,
};

@class AWSKinesisVideoSignalingGetIceServerConfigRequest;
@class AWSKinesisVideoSignalingGetIceServerConfigResponse;
@class AWSKinesisVideoSignalingIceServer;
@class AWSKinesisVideoSignalingSendAlexaOfferToMasterRequest;
@class AWSKinesisVideoSignalingSendAlexaOfferToMasterResponse;

/**
 
 */
@interface AWSKinesisVideoSignalingGetIceServerConfigRequest : AWSRequest


/**
 
 */
@property (nonatomic, strong) NSString * _Nullable channelARN;

/**
 
 */
@property (nonatomic, strong) NSString * _Nullable clientId;

/**
 
 */
@property (nonatomic, assign) AWSKinesisVideoSignalingService service;

/**
 
 */
@property (nonatomic, strong) NSString * _Nullable username;

@end

/**
 
 */
@interface AWSKinesisVideoSignalingGetIceServerConfigResponse : AWSModel


/**
 
 */
@property (nonatomic, strong) NSArray<AWSKinesisVideoSignalingIceServer *> * _Nullable iceServerList;

@end

/**
 
 */
@interface AWSKinesisVideoSignalingIceServer : AWSModel


/**
 
 */
@property (nonatomic, strong) NSString * _Nullable password;

/**
 
 */
@property (nonatomic, strong) NSNumber * _Nullable ttl;

/**
 
 */
@property (nonatomic, strong) NSArray<NSString *> * _Nullable uris;

/**
 
 */
@property (nonatomic, strong) NSString * _Nullable username;

@end

/**
 
 */
@interface AWSKinesisVideoSignalingSendAlexaOfferToMasterRequest : AWSRequest


/**
 
 */
@property (nonatomic, strong) NSString * _Nullable channelARN;

/**
 
 */
@property (nonatomic, strong) NSString * _Nullable messagePayload;

/**
 
 */
@property (nonatomic, strong) NSString * _Nullable senderClientId;

@end

/**
 
 */
@interface AWSKinesisVideoSignalingSendAlexaOfferToMasterResponse : AWSModel


/**
 
 */
@property (nonatomic, strong) NSString * _Nullable answer;

@end

NS_ASSUME_NONNULL_END
