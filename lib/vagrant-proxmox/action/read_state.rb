module VagrantPlugins
	module Proxmox
		module Action

			# This action reads the state of a Proxmox virtual machine and stores it
			# in env[:machine_state_id].
			class ReadState < ProxmoxAction

				def initialize app, env
					@app = app
					@logger = Log4r::Logger.new 'vagrant_proxmox::action::read_state'
				end

				def call env
					if !$machine_state.key?(env[:machine].name) || $machine_state_changed
						begin
							env[:machine_state_id] =
								if env[:machine].id
									node, vm_id = env[:machine].id.split '/'
									env[:proxmox_connection].get_vm_state vm_id
								else
									data = env[:proxmox_connection].find_qemu_vm(env[:machine].provider_config.vm_name_prefix, env[:machine].name)
									if data
										node, vm_id = data.split('/')
										env[:machine].id = "#{node}/#{vm_id}"
										env[:proxmox_connection].get_vm_state vm_id
									else
										:not_created
									end
								end
						rescue => e
							raise Errors::CommunicationError, error_msg: e.message
						end
					else
						env[:machine_state_id] = $machine_state[env[:machine].name]
					end
					next_action env
				end
			end
		end
	end
end
