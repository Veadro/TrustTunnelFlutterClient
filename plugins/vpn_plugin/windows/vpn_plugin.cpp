#include "vpn_plugin.h"

#include <algorithm>

using flutter::EncodableValue;

namespace vpn_plugin {

// ---------------- MockStorage ----------------
MockStorage::MockStorage() { SetupMockData(); }

void MockStorage::SetupMockData() {
  routing_profiles_ = {
      RoutingProfile{1, "Default Profile", RoutingMode::kVpn,
                     {"192.168.1.0/24", "10.0.0.0/8"}, {"*"}},
      RoutingProfile{2, "Work Profile", RoutingMode::kBypass,
                     {"company.com", "*.internal"}, {"social.com", "*.entertainment"}},
  };

  servers_ = {
      Server{1, "192.168.1.100", "vpn1.example.com", "user1", "password1",
             {"8.8.8.8", "8.8.4.4"}, VpnProtocol::kQuic, 1},
      Server{2, "10.0.0.50", "vpn2.example.com", "user2", "password2",
             {"1.1.1.1", "1.0.0.1"}, VpnProtocol::kHttp2, 2},
  };

  selected_server_id_ = 1;
  excluded_routes_ = "192.168.0.0/16,10.0.0.0/8";

  requests_ = {
      VpnRequest{"2024-08-22T12:00:00Z", "HTTPS", RoutingMode::kVpn, "192.168.1.10",
                 "8.8.8.8", "54321", "443", "google.com"}};
}

// ---------------- StreamHandler ----------------
VpnEventStreamHandler::VpnEventStreamHandler(MockStorage* storage)
    : storage_(storage) {}

void VpnEventStreamHandler::EmitState(VpnManagerState state) {
  std::lock_guard<std::mutex> lock(mutex_);
  if (!sink_) return;
  sink_->Success(EncodableValue(static_cast<int64_t>(state)));
}

std::unique_ptr<flutter::StreamHandlerError<EncodableValue>>
VpnEventStreamHandler::OnListenInternal(
    const EncodableValue* /*arguments*/,
    std::unique_ptr<flutter::EventSink<EncodableValue>>&& events) {
  {
    std::lock_guard<std::mutex> lock(mutex_);
    sink_ = std::move(events);
  }
  EmitState(storage_->CurrentVpnState());
  return nullptr;
}

std::unique_ptr<flutter::StreamHandlerError<EncodableValue>>
VpnEventStreamHandler::OnCancelInternal(const EncodableValue* /*arguments*/) {
  std::lock_guard<std::mutex> lock(mutex_);
  sink_.reset();
  return nullptr;
}

// ---------------- Managers ----------------
IVpnManagerImpl::IVpnManagerImpl(MockStorage* storage, VpnEventStreamHandler* handler)
    : storage_(storage), handler_(handler) {}

void IVpnManagerImpl::Start() {
  storage_->CurrentVpnState() = VpnManagerState::kConnected;
  handler_->EmitState(storage_->CurrentVpnState());
}

void IVpnManagerImpl::Stop() {
  storage_->CurrentVpnState() = VpnManagerState::kDisconnected;
  handler_->EmitState(storage_->CurrentVpnState());
}

VpnManagerState IVpnManagerImpl::GetCurrentState() { return storage_->CurrentVpnState(); }

AddNewServerResult ServersManagerImpl::AddNewServer(const std::string& /*name*/,
                                                    const std::string& ip,
                                                    const std::string& domain,
                                                    const std::string& user,
                                                    const std::string& pass,
                                                    VpnProtocol proto,
                                                    int64_t routing_profile_id,
                                                    const std::string& dns_csv) {
  if (ip.empty() || !IsValidIp(ip)) return AddNewServerResult::kIpAddressIncorrect;
  if (domain.empty()) return AddNewServerResult::kDomainIncorrect;
  if (user.empty()) return AddNewServerResult::kUsernameIncorrect;
  if (pass.empty()) return AddNewServerResult::kPasswordIncorrect;

  auto dns = SplitAndTrim(dns_csv, ',');
  if (dns.empty()) return AddNewServerResult::kDnsServersIncorrect;

  int64_t new_id = 1;
  for (const auto& s : storage_->AllServers()) new_id = (std::max)(new_id, s.id + 1);

  storage_->AllServers().push_back(
      Server{new_id, ip, domain, user, pass, dns, proto, routing_profile_id});
  return AddNewServerResult::kOk;
}

AddNewServerResult ServersManagerImpl::SetNewServer(int64_t id, const std::string& /*name*/,
                                                    const std::string& ip,
                                                    const std::string& domain,
                                                    const std::string& user,
                                                    const std::string& pass,
                                                    VpnProtocol proto,
                                                    int64_t routing_profile_id,
                                                    const std::string& dns_csv) {
  if (ip.empty() || !IsValidIp(ip)) return AddNewServerResult::kIpAddressIncorrect;
  if (domain.empty()) return AddNewServerResult::kDomainIncorrect;
  if (user.empty()) return AddNewServerResult::kUsernameIncorrect;
  if (pass.empty()) return AddNewServerResult::kPasswordIncorrect;

  auto dns = SplitAndTrim(dns_csv, ',');
  if (dns.empty()) return AddNewServerResult::kDnsServersIncorrect;

  auto& all = storage_->AllServers();
  for (auto& s : all) {
    if (s.id == id) {
      s = Server{id, ip, domain, user, pass, dns, proto, routing_profile_id};
      break;
    }
  }
  return AddNewServerResult::kOk;
}

void ServersManagerImpl::RemoveServer(int64_t id) {
  auto& all = storage_->AllServers();
  all.erase(std::remove_if(all.begin(), all.end(), [&](const Server& s) { return s.id == id; }),
            all.end());
  if (storage_->CurrentSelectedServerId().has_value() &&
      storage_->CurrentSelectedServerId().value() == id) {
    storage_->CurrentSelectedServerId().reset();
  }
}

bool ServersManagerImpl::IsValidIp(const std::string& ip) {
  auto parts = SplitAndTrim(ip, '.');
  if (parts.size() != 4) return false;
  for (auto& p : parts) {
    try {
      int v = std::stoi(p);
      if (v < 0 || v > 255) return false;
    } catch (...) { return false; }
  }
  return true;
}

std::vector<std::string> ServersManagerImpl::SplitAndTrim(const std::string& s, char delim) {
  std::vector<std::string> out;
  std::string cur;
  for (char c : s) {
    if (c == delim) {
      Trim(cur);
      if (!cur.empty()) out.push_back(cur);
      cur.clear();
    } else {
      cur.push_back(c);
    }
  }
  Trim(cur);
  if (!cur.empty()) out.push_back(cur);
  return out;
}

void ServersManagerImpl::Trim(std::string& str) {
  auto not_space = [](int ch) { return !std::isspace(ch); };
  str.erase(str.begin(), std::find_if(str.begin(), str.end(), not_space));
  str.erase(std::find_if(str.rbegin(), str.rend(), not_space).base(), str.end());
}

void RoutingProfilesManagerImpl::AddNewProfile() {
  int64_t new_id = 1;
  for (const auto& p : storage_->AllRoutingProfiles()) new_id = (std::max)(new_id, p.id + 1);
  storage_->AllRoutingProfiles()
      .push_back(RoutingProfile{new_id, "Profile " + std::to_string(new_id), RoutingMode::kVpn, {}, {}});
}

void RoutingProfilesManagerImpl::SetDefaultRoutingMode(int64_t id, RoutingMode mode) {
  for (auto& p : storage_->AllRoutingProfiles()) { if (p.id == id) { p.default_mode = mode; break; } }
}

void RoutingProfilesManagerImpl::SetProfileName(int64_t id, const std::string& name) {
  for (auto& p : storage_->AllRoutingProfiles()) { if (p.id == id) { p.name = name; break; } }
}

void RoutingProfilesManagerImpl::SetRules(int64_t id, RoutingMode mode, const std::string& rules) {
  auto arr = ServersManagerImpl::SplitAndTrim(rules, '\n');
  for (auto& p : storage_->AllRoutingProfiles()) {
    if (p.id == id) {
      if (mode == RoutingMode::kBypass) p.bypass_rules = arr; else p.vpn_rules = arr;
      break;
    }
  }
}

void RoutingProfilesManagerImpl::RemoveAllRules(int64_t id) {
  for (auto& p : storage_->AllRoutingProfiles()) {
    if (p.id == id) { p.bypass_rules.clear(); p.vpn_rules.clear(); break; }
  }
}

// ---------------- VpnPlugin ----------------
void VpnPlugin::RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar) {
  auto messenger = registrar->messenger();

  auto storage = std::make_shared<MockStorage>();
  auto handler = std::make_unique<VpnEventStreamHandler>(storage.get());

  auto event_channel = std::make_unique<flutter::EventChannel<EncodableValue>>(
      messenger, "vpn_plugin_event_channel", &flutter::StandardMethodCodec::GetInstance());
  event_channel->SetStreamHandler(std::unique_ptr<VpnEventStreamHandler>(handler.get()));

  auto vpn_manager = std::make_unique<IVpnManagerImpl>(storage.get(), handler.get());
  auto storage_manager = std::make_unique<StorageManagerImpl>(storage.get());
  auto servers_manager = std::make_unique<ServersManagerImpl>(storage.get());
  auto routing_manager = std::make_unique<RoutingProfilesManagerImpl>(storage.get());

  IVpnManagerSetupSetUp(messenger, vpn_manager.get());
  IStorageManagerSetupSetUp(messenger, storage_manager.get());
  ServersManagerSetupSetUp(messenger, servers_manager.get());
  RoutingProfilesManagerSetupSetUp(messenger, routing_manager.get());

  registrar->AddPlugin(std::make_unique<VpnPlugin>(
      std::move(event_channel), storage, std::move(handler), std::move(vpn_manager),
      std::move(storage_manager), std::move(servers_manager), std::move(routing_manager)));
}

VpnPlugin::VpnPlugin(
    std::unique_ptr<flutter::EventChannel<EncodableValue>> event_channel,
    std::shared_ptr<MockStorage> storage,
    std::unique_ptr<VpnEventStreamHandler> handler,
    std::unique_ptr<IVpnManagerImpl> vpn_manager,
    std::unique_ptr<StorageManagerImpl> storage_manager,
    std::unique_ptr<ServersManagerImpl> servers_manager,
    std::unique_ptr<RoutingProfilesManagerImpl> routing_manager)
    : event_channel_(std::move(event_channel)),
      storage_(std::move(storage)),
      handler_(std::move(handler)),
      vpn_manager_(std::move(vpn_manager)),
      storage_manager_(std::move(storage_manager)),
      servers_manager_(std::move(servers_manager)),
      routing_manager_(std::move(routing_manager)) {}

VpnPlugin::~VpnPlugin() = default;

}  // namespace vpn_plugin
