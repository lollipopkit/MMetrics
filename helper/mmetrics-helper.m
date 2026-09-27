#import <Foundation/Foundation.h>
#import "../MMetrics/IOReportWrapper.h"
#import "../MMetrics/SMC.h"

static NSDictionary *collectMetrics(void) {
    io_connect_t conn = SMCOpen();
    IOReportData data = [IOReportWrapper fetchIOReportDataWithSMC:conn];
    if (conn != 0) {
        SMCClose(conn);
    }

    return @{
        @"cpuTemp": @(data.cpuTemp),
        @"cpuDieHotspot": @(data.cpuDieHotspot),
        @"gpuTemp": @(data.gpuTemp),
        @"cpuPower": @(data.cpuPower),
        @"gpuPower": @(data.gpuPower),
        @"anePower": @(data.anePower),
        @"dramPower": @(data.dramPower),
        @"systemPower": @(data.systemPower),
        @"gpuUsage": @(data.gpuUsage),
        @"gpuFreqMHz": @(data.gpuFreqMHz),
        @"eClusterActive": @(data.eClusterActive),
        @"pClusterActive": @(data.pClusterActive),
        @"eClusterFreqMHz": @(data.eClusterFreqMHz),
        @"pClusterFreqMHz": @(data.pClusterFreqMHz),
        @"sClusterActive": @(data.sClusterActive),
        @"sClusterFreqMHz": @(data.sClusterFreqMHz),
        @"dramReadBytes": @(data.dramReadBytes),
        @"dramWriteBytes": @(data.dramWriteBytes),
        @"fanRPM": @(data.fanRPM),
        @"socEnergyAvailable": @(data.socEnergyAvailable),
        @"dramBandwidthAvailable": @(data.dramBandwidthAvailable)
    };
}

int main(void) {
    @autoreleasepool {
        NSDictionary *payload = collectMetrics();
        NSError *error = nil;
        NSData *json = [NSJSONSerialization dataWithJSONObject:payload options:0 error:&error];
        if (json == nil) {
            fprintf(stderr, "json_error=%s\n", error.localizedDescription.UTF8String ?: "unknown");
            return 1;
        }
        fwrite(json.bytes, 1, json.length, stdout);
    }
    return 0;
}
