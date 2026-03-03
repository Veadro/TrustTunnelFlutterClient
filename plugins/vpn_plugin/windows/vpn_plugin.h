#ifndef FLUTTER_PLUGIN_VPN_PLUGIN_H_
#define FLUTTER_PLUGIN_VPN_PLUGIN_H_

#include <flutter/event_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/task_runner.h>

#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <vector>

namespace vpn_plugin {

enum class VpnManagerState : int64_t { kDisconnected = 0, kConnecting = 1, kConnected = 2 };
enum class VpnProtocol : int64_t { kQuic = 0, kHttp2 = 1 };
enum class RoutingMode : int64_t { kVpn = 0, kBypass = 1 };

struct Server {
  int64_t id;
  std::string ip_address;
  std::string domain;
  std::string login;
  std::string password;
  std::vector<std::string> dns_servers;
  VpnProtocol vpn_protocol;
  int64_t routing_profile_id;
};

struct RoutingProfile {
  int64_t id;
  std::string name;
  RoutingMode default_mode;
  std::vector<std::string> bypass_rules;
  std::vector<std::string> vpn_rules;
};

struct VpnRequest {
  std::string zoned_date_time;
  std::string protocol_name;
  RoutingMode decision;
  std::string source_ip_address;
  std::string destination_ip_address;
  std::string source_port;
  std::string destination_port;
  std::string domain;
};

enum class AddNewServerResult : int64_t {
  kOk = 0,
  kIpAddressIncorrect = 1,
  kDomainIncorrect = 2,
  kUsernameIncorrect = 3,
  kPasswordIncorrect = 4,
  kDnsServersIncorrect = 5
};

void IVpnManagerSetupSetUp(flutter::BinaryMessenger*, void* /*api*/);
void IStorageManagerSetupSetUp(flutter::BinaryMessenger*, void* /*api*/);
void ServersManagerSetupSetUp(flutter::BinaryMessenger*, void* /*api*/);
void RoutingProfilesManagerSetupSetUp(flutter::BinaryMessenger*, void* /*api*/);

class MockStorage {
 public:
  MockStorage();

  std::vector<Server>& AllServers() { return servers_; }
  std::vector<RoutingProfile>& AllRoutingProfiles() { return routing_profiles_; }
  std::optional<int64_t>& CurrentSelectedServerId() { return selected_server_id_; }
  std::string& CurrentExcludedRoutes() { return excluded_routes_; }
  VpnManagerState& CurrentVpnState() { return vpn_state_; }
  std::vector<VpnRequest>& AllRequests() { return requests_; }

 private:
  void SetupMockData();

  std::vector<Server> servers_;
  std::vector<RoutingProfile> routing_profiles_;
  std::optional<int64_t> selected_server_id_;
  std::string excluded_routes_;
  VpnManagerState vpn_state_ = VpnManagerState::kDisconnected;
  std::vector<VpnRequest> requests_;
};

class VpnEventStreamHandler
    : public flutter::StreamHandler<flutter::EncodableValue> {
 public:
  explicit VpnEventStreamHandler(MockStorage* storage,
                                 std::shared_ptr<flutter::TaskRunner> ui_runner);

  void EmitState(VpnManagerState state);

 protected:
  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> OnListenInternal(
      const flutter::EncodableValue* arguments,
      std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events) override;

  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> OnCancelInternal(
      const flutter::EncodableValue* arguments) override;

 private:
  MockStorage* storage_;
  std::shared_ptr<flutter::TaskRunner> ui_runner_;
  std::mutex mutex_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink_;
};

class IVpnManagerImpl {
 public:
  IVpnManagerImpl(MockStorage* storage, VpnEventStreamHandler* handler,
                  std::shared_ptr<flutter::TaskRunner> ui_runner);
  void Start();
  void Stop();
  VpnManagerState GetCurrentState();

 private:
  MockStorage* storage_;
  VpnEventStreamHandler* handler_;
  std::shared_ptr<flutter::TaskRunner> ui_runner_;
};

class StorageManagerImpl {
 public:
  explicit StorageManagerImpl(MockStorage* storage) : storage_(storage) {}
  void SetExcludedRoutes(const std::string& routes) { storage_->CurrentExcludedRoutes() = routes; }
  void SetRoutingProfiles(const std::vector<RoutingProfile>& profiles) { storage_->AllRoutingProfiles() = profiles; }
  void SetSelectedServerId(int64_t id) { storage_->CurrentSelectedServerId() = id; }
  void SetServers(const std::vector<Server>& servers) { storage_->AllServers() = servers; }
  std::vector<VpnRequest> GetAllRequests() { return storage_->AllRequests(); }
  std::string GetExcludedRoutes() { return storage_->CurrentExcludedRoutes(); }
  std::vector<RoutingProfile> GetRoutingProfiles() { return storage_->AllRoutingProfiles(); }
  std::optional<int64_t> GetSelectedServerId() { return storage_->CurrentSelectedServerId(); }
  std::vector<Server> GetAllServers() { return storage_->AllServers(); }

 private:
  MockStorage* storage_;
};

class ServersManagerImpl {
 public:
  explicit ServersManagerImpl(MockStorage* storage) : storage_(storage) {}
  AddNewServerResult AddNewServer(const std::string& name, const std::string& ip,
                                  const std::string& domain, const std::string& user,
                                  const std::string& pass, VpnProtocol proto,
                                  int64_t routing_profile_id, const std::string& dns_csv);
  std::vector<Server> GetAllServers() { return storage_->AllServers(); }
  AddNewServerResult SetNewServer(int64_t id, const std::string& name, const std::string& ip,
                                  const std::string& domain, const std::string& user,
                                  const std::string& pass, VpnProtocol proto,
                                  int64_t routing_profile_id, const std::string& dns_csv);
  void SetSelectedServerId(int64_t id) { storage_->CurrentSelectedServerId() = id; }
  void RemoveServer(int64_t id);

  static bool IsValidIp(const std::string& ip);
  static std::vector<std::string> SplitAndTrim(const std::string& s, char delim);
  static void Trim(std::string& s);

 private:
  MockStorage* storage_;
};

class RoutingProfilesManagerImpl {
 public:
  explicit RoutingProfilesManagerImpl(MockStorage* storage) : storage_(storage) {}
  void AddNewProfile();
  std::vector<RoutingProfile> GetAllProfiles() { return storage_->AllRoutingProfiles(); }
  void SetDefaultRoutingMode(int64_t id, RoutingMode mode);
  void SetProfileName(int64_t id, const std::string& name);
  void SetRules(int64_t id, RoutingMode mode, const std::string& rules);
  void RemoveAllRules(int64_t id);

 private:
  MockStorage* storage_;
};

class VpnPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  explicit VpnPlugin(
      std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> event_channel,
      std::shared_ptr<MockStorage> storage,
      std::unique_ptr<VpnEventStreamHandler> handler,
      std::unique_ptr<IVpnManagerImpl> vpn_manager,
      std::unique_ptr<StorageManagerImpl> storage_manager,
      std::unique_ptr<ServersManagerImpl> servers_manager,
      std::unique_ptr<RoutingProfilesManagerImpl> routing_manager);

  ~VpnPlugin() override;

  VpnPlugin(const VpnPlugin&) = delete;
  VpnPlugin& operator=(const VpnPlugin&) = delete;

 private:
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> event_channel_;
  std::shared_ptr<MockStorage> storage_;
  std::unique_ptr<VpnEventStreamHandler> handler_;
  std::unique_ptr<IVpnManagerImpl> vpn_manager_;
  std::unique_ptr<StorageManagerImpl> storage_manager_;
  std::unique_ptr<ServersManagerImpl> servers_manager_;
  std::unique_ptr<RoutingProfilesManagerImpl> routing_manager_;
};

}  // namespace vpn_plugin

#endif  // FLUTTER_PLUGIN_VPN_PLUGIN_H_