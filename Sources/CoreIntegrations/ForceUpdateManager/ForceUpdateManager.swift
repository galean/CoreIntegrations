//
//  ForceUpdateManager.swift
//
//
//  Created by Anatolii Kanarskyi on 3/1/24.
//

import UIKit

struct ForceUpdateManager {
    public static func isAppUpdateNeeded(_ fbVersion: String) -> ForceUpdateResult? {
        let nsObject: AnyObject? = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as AnyObject
        guard let version = nsObject as? String else {
            return nil
        }
        let currentVersion = formatAppVersionToInt(appVersion: version)
        let latestSupportedVersionString = fbVersion
        let latestSupportedVersion = formatAppVersionToInt(appVersion: latestSupportedVersionString)

        return ForceUpdateResult(currentVersion: version, newVersion: fbVersion, appUpdateRequired: currentVersion < latestSupportedVersion)
    }
    
    private static func formatAppVersionToInt(appVersion: String) -> Int {
        var versionInt = Int(appVersion.replacingOccurrences(of: ".", with: "")) ?? 0
        if versionInt < 100 {
            versionInt *= 10
        }
        return versionInt
    }
    
}
