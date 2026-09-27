// IOReportWrapper.h
#import <Foundation/Foundation.h>

typedef struct {
    double cpuPower;        // Watts — aggregate CPU Energy (E+P cores)
    double gpuPower;        // Watts — GPU Energy
    double anePower;        // Watts — Neural Engine Energy
    double dramPower;       // Watts — DRAM Energy
    double systemPower;     // Watts — total board power (SMC PSTR)
    double cpuTemp;         // Celsius — average across CPU core sensors (SMC Tp*/Te*)
    double cpuDieHotspot;   // Celsius — absolute hottest CPU die point (SMC TCMz)
    double gpuTemp;         // Celsius — average across GPU sensors (SMC Tg*)
    double gpuUsage;        // Percent (0-100)
    int    gpuFreqMHz;
    double eClusterActive;  // Percent (0-100) — Efficiency cluster
    double pClusterActive;  // Percent (0-100) — Performance cluster (M1-M4) or Medium tier (M5+)
    int    eClusterFreqMHz;
    int    pClusterFreqMHz;
    double sClusterActive;  // Percent (0-100) — Super cluster (M5+ only)
    int    sClusterFreqMHz;
    int64_t dramReadBytes;
    int64_t dramWriteBytes;
    int32_t fanRPM;         // RPM — Fan 0 actual speed (SMC F0Ac); 0 on fanless models
    bool   socEnergyAvailable; // false when IOReport "Energy Model" CPU/ANE/DRAM counters read 0 (M5 Pro, macOS 27)
    bool   dramBandwidthAvailable; // false when neither AMC Stats nor PMP "DRAM BW" byte counters exist
} IOReportData;

@interface IOReportWrapper : NSObject
+ (IOReportData)fetchIOReportData;
+ (IOReportData)fetchIOReportDataWithSMC:(io_connect_t)smcConn;
@end
