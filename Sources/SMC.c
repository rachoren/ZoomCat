// SMC.c — 通过 AppleSMC 读取温度（Intel Mac，无需 root）
// 数据结构与协议参考 osx-cpu-temp / SMCKit
#include <IOKit/IOKitLib.h>
#include <string.h>
#include <stdint.h>

typedef struct {
    char major, minor, build, reserved, release[16];
} SMCKeyData_vers_t;

typedef struct {
    uint16_t version;
    uint16_t length;
    uint32_t cpuPLimit;
    uint32_t gpuPLimit;
    uint32_t memPLimit;
} SMCKeyData_pLimitData_t;

typedef struct {
    uint32_t dataSize;
    uint32_t dataType;
    char dataAttributes;
} SMCKeyData_keyInfo_t;

typedef char SMCBytes_t[32];

typedef struct {
    uint32_t key;
    SMCKeyData_vers_t vers;
    SMCKeyData_pLimitData_t pLimitData;
    SMCKeyData_keyInfo_t keyInfo;
    char result;
    char status;
    char data8;
    uint32_t data32;
    SMCBytes_t bytes;
} SMCKeyData_t;

#define KERNEL_INDEX_SMC      2
#define SMC_CMD_READ_BYTES    5
#define SMC_CMD_READ_KEYINFO  9

static io_connect_t g_conn = 0;
static int g_opened = 0;

static kern_return_t smc_call(SMCKeyData_t *input, SMCKeyData_t *output) {
    size_t size = sizeof(SMCKeyData_t);
    return IOConnectCallStructMethod(g_conn, KERNEL_INDEX_SMC, input, sizeof(SMCKeyData_t), output, &size);
}

int smc_open(void) {
    if (g_opened) return 1;
    io_service_t service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleSMC"));
    if (service == 0) return 0;
    kern_return_t r = IOServiceOpen(service, mach_task_self(), 0, &g_conn);
    IOObjectRelease(service);
    if (r != kIOReturnSuccess) return 0;
    g_opened = 1;
    return 1;
}

void smc_close(void) {
    if (g_opened) {
        IOServiceClose(g_conn);
        g_opened = 0;
    }
}

static int smc_read_key(uint32_t key, SMCKeyData_t *out) {
    if (!g_opened) return 0;
    SMCKeyData_t input, output;
    memset(&input, 0, sizeof(input));
    memset(&output, 0, sizeof(output));

    // 1) 查询 key 信息（数据大小/类型）
    input.key = key;
    input.data8 = SMC_CMD_READ_KEYINFO;
    if (smc_call(&input, &output) != kIOReturnSuccess) return 0;
    if (output.result != 0) return 0;

    // 2) 读取字节
    memset(&input, 0, sizeof(input));
    input.key = key;
    input.keyInfo.dataSize = output.keyInfo.dataSize;
    input.data8 = SMC_CMD_READ_BYTES;
    if (smc_call(&input, &output) != kIOReturnSuccess) return 0;
    if (output.result != 0) return 0;

    memcpy(out, &output, sizeof(SMCKeyData_t));
    return 1;
}

// 读取 sp78（signed 16.8 定点）温度键；失败返回 -1
double smc_temp_celsius(const char *key) {
    uint32_t k = ((uint32_t)(unsigned char)key[0] << 24) |
                 ((uint32_t)(unsigned char)key[1] << 16) |
                 ((uint32_t)(unsigned char)key[2] << 8) |
                 ((uint32_t)(unsigned char)key[3]);
    SMCKeyData_t data;
    if (!smc_read_key(k, &data)) return -1.0;
    if (data.keyInfo.dataType != ((uint32_t)'s' << 24 | (uint32_t)'p' << 16 | (uint32_t)'7' << 8 | (uint32_t)'8')) {
        return -1.0;
    }
    if (data.keyInfo.dataSize != 2) return -1.0;
    int16_t value = (int16_t)((data.bytes[0] << 8) | data.bytes[1]);
    return (double)value / 256.0;
}

// 读取 CPU 相关温度键中的最高值（°C），全部失败返回 -1
double smc_cpu_temp(void) {
    const char *keys[] = {"TC0P", "TC0D", "TC1C", "TC2C", "TC3C", "TC4C",
                          "TC5C", "TC6C", "TC7C", "TC8C", "Tp09"};
    double best = -1.0;
    int n = (int)(sizeof(keys) / sizeof(keys[0]));
    for (int i = 0; i < n; i++) {
        double t = smc_temp_celsius(keys[i]);
        if (t > 0 && t > best) best = t;
    }
    return best;
}
