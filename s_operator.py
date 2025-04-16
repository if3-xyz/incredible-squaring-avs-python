import os
import time
import json
import logging
from random import randbytes
import yaml
from eth_account import Account
from eigensdk.chainio.clients.builder import BuildAllConfig
from eigensdk.crypto.bls.attestation import BLSKeyPair
from eigensdk._types import Operator
from web3 import Web3
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class SquaringOperator:
    def __init__(self, config):
        self.config = config
        self.__load_bls_key()
        self.__load_ecdsa_key()
        self.__load_clients()
        if config["register_operator_on_startup"] == 'true':
            self.register()
        
    def register(self):
        operator = Operator(
            address=self.config["operator_address"],
            earnings_receiver_address=self.config["operator_address"],
            delegation_approver_address="0x0000000000000000000000000000000000000000",
            staker_opt_out_window_blocks=0,
            metadata_url="",
        )
        self.el_writer.register_as_operator(operator, True)
        self.avs_registry_writer.register_operator_in_quorum_with_avs_registry_coordinator(
            operator_ecdsa_private_key=self.operator_ecdsa_private_key,
            operator_to_avs_registration_sig_salt=randbytes(32),
            operator_to_avs_registration_sig_expiry=int(time.time()) + 3600,
            bls_key_pair=self.bls_key_pair,
            quorum_numbers=[0],
            socket="Not Needed",
        )

    def __load_bls_key(self):
        bls_key_password = os.environ.get("OPERATOR_BLS_KEY_PASSWORD", "")
        if not bls_key_password:
            logger.warning("OPERATOR_BLS_KEY_PASSWORD not set. using empty string.")

        self.bls_key_pair = BLSKeyPair.read_from_file(
            self.config["bls_private_key_store_path"], bls_key_password
        )

    def __load_ecdsa_key(self):
        ecdsa_key_password = os.environ.get("OPERATOR_ECDSA_KEY_PASSWORD", "")
        if not ecdsa_key_password:
            logger.warning("OPERATOR_ECDSA_KEY_PASSWORD not set. using empty string.")

        with open(self.config["ecdsa_private_key_store_path"], "r") as f:
            keystore = json.load(f)
        self.operator_ecdsa_private_key = Account.decrypt(keystore, ecdsa_key_password).hex()

    def __load_clients(self):
        # Read core addresses
        with open("contracts/script/deployments/core/31337.json", "r") as f:
            core_addresses_raw = json.load(f)["addresses"]
        
        # Read AVS-specific addresses
        with open("contracts/script/deployments/incredible-squaring/31337.json", "r") as f:
            avs_addresses_raw = json.load(f)["addresses"]

        # Convert addresses to checksum format
        core_addresses = {k: Web3.to_checksum_address(v) for k, v in core_addresses_raw.items()}
        avs_addresses = {k: Web3.to_checksum_address(v) for k, v in avs_addresses_raw.items()}

        config = BuildAllConfig(
            eth_http_url=self.config["eth_rpc_url"],
            avs_name="incredible-squaring",
            registry_coordinator_addr=avs_addresses["registryCoordinator"],
            operator_state_retriever_addr=avs_addresses["operatorStateRetriever"],
            prom_metrics_ip_port_address=self.config["eigen_metrics_ip_port_address"],
        )

        # Build EL reader client using addresses from deployment files
        self.el_reader = config.build_el_reader_clients(
            allocation_manager=core_addresses["allocationManager"],
            avs_directory=core_addresses["avsDirectory"],
            delegation_manager=core_addresses["delegation"],
            permission_controller=core_addresses["permissionController"],
            reward_coordinator=core_addresses["rewardsCoordinator"],
            strategy_manager=core_addresses["strategyManager"],
        )

        # Build EL writer client using addresses from deployment files
        self.el_writer = config.build_el_writer_clients(
            sender_address=self.config["operator_address"],
            private_key=self.operator_ecdsa_private_key,
            allocation_manager=core_addresses["allocationManager"],
            avs_directory=core_addresses["avsDirectory"],
            delegation_manager=core_addresses["delegation"],
            permission_controller=core_addresses["permissionController"],
            reward_coordinator=core_addresses["rewardsCoordinator"],
            registry_coordinator=avs_addresses["registryCoordinator"],
            strategy_manager=core_addresses["strategyManager"],
            strategy_manager_addr=avs_addresses["strategy"],
            el_chain_reader=self.el_reader,
        )

        # Build AVS registry reader client using addresses from deployment files
        self.avs_registry_reader = config.build_avs_registry_reader_clients(
            sender_address=self.config["operator_address"],
            private_key=self.operator_ecdsa_private_key,
            registry_coordinator=avs_addresses["registryCoordinator"],
            registry_coordinator_addr=avs_addresses["registryCoordinator"],
            bls_apk_registry=avs_addresses["blsapkRegistry"],
            bls_apk_registry_addr=avs_addresses["blsapkRegistry"],
            operator_state_retriever=avs_addresses["operatorStateRetriever"],
            service_manager=avs_addresses["incredibleSquaringServiceManager"],
            stake_registry=avs_addresses["stakeRegistry"],
        )

        # Build AVS registry writer client using addresses from deployment files
        self.avs_registry_writer = config.build_avs_registry_writer_clients(
            registry_coordinator=avs_addresses["registryCoordinator"],
            operator_state_retriever=avs_addresses["operatorStateRetriever"],
            service_manager=avs_addresses["incredibleSquaringServiceManager"],
            service_manager_addr=avs_addresses["incredibleSquaringServiceManager"],
            stake_registry=avs_addresses["stakeRegistry"],
            bls_apk_registry=avs_addresses["blsapkRegistry"],
            el_chain_reader=self.el_reader,
        )

if __name__ == "__main__":
    with open("config-files/operator.anvil.yaml", "r") as f:
        config = yaml.load(f, Loader=yaml.BaseLoader)

    SquaringOperator(config=config).start()

