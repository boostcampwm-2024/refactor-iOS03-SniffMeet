//
//  NIManager.swift
//  SniffMeet
//
//  Created by 배현진 on 11/14/24.
//

import Combine
import MultipeerConnectivity
import NearbyInteraction

final class NIManager: NSObject {
    private var niSession: NISession?
    private var cancellables = Set<AnyCancellable>()
    private let minDistance: Float = 0.09
    private let maxDistance: Float = 0.15
    private let minDirection: simd_float3 = simd_float3(-0.6, -0.3, -1.0)
    private let maxDirection: simd_float3 = simd_float3(0.6, 0.3, -0.8)

    @Published var niPaired: Bool = false
    var mpcManager: MPCManager
    var isViewTransitioning = PassthroughSubject<Bool, Never>()
    var viewTransitionInfo = Set<String>()

    init(mpcManager: MPCManager) {
        self.mpcManager = mpcManager
        super.init()

        setupNISession()
        setupBindings()
    }

    private func setupNISession() {
        niSession = NISession()
        niSession?.delegate = self
    }

    private func setupBindings() {
        // MPC 연결 완료 시 discoveryToken을 주고받기
        mpcManager.$paired
            .receive(on: RunLoop.main)
            .sink { [weak self] isPaired in
                if isPaired {
                    self?.sendDiscoveryToken()
                }
            }
            .store(in: &cancellables)

        // MPC로 discoveryToken 수신 시 NI 세션 업데이트
        mpcManager.receivedTokenPublisher
            .sink { [weak self] token in
                self?.handleReceivedDiscoveryToken(token)
            }
            .store(in: &cancellables)

        mpcManager.receivedViewTransitionPublisher
            .sink { [weak self] isViewTransitioning in
                self?.viewTransitionInfo.insert(isViewTransitioning) // receive 메세지가 들어옴
                SNMLogger.info("viewTrnasitionInfo: \(self?.viewTransitionInfo ?? [])")
                
                if self?.viewTransitionInfo.count == 2 {
                    self?.endSession()
                }
            }
            .store(in: &cancellables)
    }

    // discoveryToken 전송
    private func sendDiscoveryToken() {
        guard let niSession = niSession, let discoveryToken = niSession.discoveryToken else {
            SNMLogger.log("Discovery token is not available.")
            return
        }

        do {
            let tokenData = try NSKeyedArchiver.archivedData(
                withRootObject: discoveryToken,
                requiringSecureCoding: true
            )
            mpcManager.sendToken(discoveryToken: tokenData)
            SNMLogger.log("Discovery token sent to peer.")
        } catch {
            SNMLogger.error("Failed to encode discovery token: \(error)")
        }
    }

    // discoveryToken 수신 처리
    private func handleReceivedDiscoveryToken(_ data: Data) {
        do {
            guard let token = try NSKeyedUnarchiver.unarchivedObject(
                ofClass: NIDiscoveryToken.self,
                from: data
            ) else {
                SNMLogger.log("Invalid discovery token received.")
                return
            }

            let config = NINearbyPeerConfiguration(peerToken: token)
            niSession?.run(config)
            niPaired = true
            SNMLogger.log("NearbyInteraction session started with received discovery token.")
        } catch {
            SNMLogger.error("Failed to decode discovery token: \(error)")
        }
    }

    func endSession() {
        SNMLogger.log("NI 세션 종료")
        niSession?.invalidate()
        mpcManager.session.disconnect()
        mpcManager.isAvailableToBeConnected = false
        SNMLogger.log("MPC 세션 종료")
        niPaired = false
    }
}

// MARK: - NISessionDelegate
extension NIManager: NISessionDelegate {
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        guard let nearbyObject = nearbyObjects.first else { return }
        let distance = nearbyObject.distance ?? 1
        let direction = nearbyObject.direction ?? simd_float3(0.1, 0.1, 0.1)

        SNMLogger.info("Distance and Direction to peer: \(distance) and \(direction)")

        if distance > minDistance && distance < maxDistance {
            guard let profile = mpcManager.profile else {
                SNMLogger.log("보낼 데이터가 없다. ")
                return
            }
            SNMLogger.log("거리와 방향 조건 만족")
            mpcManager.sendData(profile: profile)
            // 전송 끝
            // 예측하지 못한 상황
            Task { @MainActor in
                isViewTransitioning.send(true) // 메이트리스트에서 화면전환을 해도 된다의 신호
                viewTransitionInfo.insert("send") // 종료 조건 중 하나를 달성했다. (자신의 프로필 데이터를 보냈다의 의미)
                // 연결 종료 요청 코드 send
                mpcManager.send(viewTransitionInfo: "receive") // ni 조건이 만족되기 전에 데이터 전송되니까
            }
        }
    }

    func sessionWasSuspended(_ session: NISession) {
        SNMLogger.log("NearbyInteraction session suspended.")
    }

    func sessionSuspensionEnded(_ session: NISession) {
        SNMLogger.log("NearbyInteraction session suspension ended.")
    }

    func session(_ session: NISession, didInvalidateWith error: Error) {
        SNMLogger.error("NearbyInteraction session invalidated: \(error)")
    }
}
