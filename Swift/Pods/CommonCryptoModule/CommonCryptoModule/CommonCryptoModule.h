//
//  CommonCryptoModule.h
//  CommonCryptoModule
//
//  Created by Nikita Kukushkin on 02/11/2017.
//  Copyright © 2017 Nikita Kukushkin. All rights reserved.
//

@import Foundation;

//! Project version number for CommonCryptoModule.
FOUNDATION_EXPORT double CommonCryptoModuleVersionNumber;

//! Project version string for CommonCryptoModule.
FOUNDATION_EXPORT const unsigned char CommonCryptoModuleVersionString[];

// Trampoline CommonCrypto with CommonCryptoModule imports.
@import CommonCryptoBridge;
