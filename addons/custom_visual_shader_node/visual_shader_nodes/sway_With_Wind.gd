@tool
extends VisualShaderNodeCustom
class_name VS_GrassWind

func _get_name() -> String:
	return "SwayWithWind"

func _get_category() -> String:
	return "Vertex"

func _get_description() -> String:
	return "Applies wind sway + noise + player push effect to vertex positions."

func _get_return_icon_type() -> int:
	return VisualShaderNode.PORT_TYPE_VECTOR_3D

# 输入端口
func _get_input_port_count() -> int:
	return 11

func _get_input_port_type(port: int) -> int:
	match port:
		0:  return VisualShaderNode.PORT_TYPE_VECTOR_3D # player_position
		1:  return VisualShaderNode.PORT_TYPE_SCALAR    # radius
		2:  return VisualShaderNode.PORT_TYPE_SCALAR    # falloff
		3:  return VisualShaderNode.PORT_TYPE_SCALAR    # strength
		4:  return VisualShaderNode.PORT_TYPE_VECTOR_2D # freq (合并 freq_x,freq_y)
		5:  return VisualShaderNode.PORT_TYPE_SCALAR    # wind_speed
		6:  return VisualShaderNode.PORT_TYPE_SCALAR    # wind_strength
		7:  return VisualShaderNode.PORT_TYPE_SCALAR    # noise_scale
		8:  return VisualShaderNode.PORT_TYPE_SCALAR    # noise_speed
		9:  return VisualShaderNode.PORT_TYPE_SAMPLER   # wind_noise
		10: return VisualShaderNode.PORT_TYPE_VECTOR_2D # wind_dir
		_:  return VisualShaderNode.PORT_TYPE_SCALAR

func _get_input_port_name(port: int) -> String:
	match port:
		0:  return "player_position"
		1:  return "radius"
		2:  return "falloff"
		3:  return "strength"
		4:  return "freq"
		5:  return "wind_speed"
		6:  return "wind_strength"
		7:  return "noise_scale"
		8:  return "noise_speed"
		9:  return "wind_noise"
		10: return "wind_dir"
		_:  return ""

# 输出端口
func _get_output_port_count() -> int:
	return 1

func _get_output_port_type(port: int) -> int:
	return VisualShaderNode.PORT_TYPE_VECTOR_3D

func _get_output_port_name(port: int) -> String:
	return "VertexOffset"

# 生成代码
func _get_code(input_vars: Array, output_vars: Array, mode: int, _type: int) -> String:
	if mode != VisualShader.MODE_SPATIAL:
		return "%s = vec3(0.0);" % [output_vars[0]]

	var player_position   = input_vars[0] if input_vars[0] != "" else "vec3(0.0, 0.0, 0.0)"
	var radius   = input_vars[1] if input_vars[1] != "" else "0.2"
	var falloff   = input_vars[2] if input_vars[2] != "" else "0.5"
	var strength   = input_vars[3] if input_vars[3] != "" else "0.6"
	var freq  = input_vars[4] if input_vars[4] != "" else "vec2(1.0, 1.0)"
	var wind_speed  = input_vars[5] if input_vars[5] != "" else "0.5"
	var wind_strength = input_vars[6] if input_vars[6] != "" else "0.2"
	var noise_scale = input_vars[7] if input_vars[7] != "" else "0.05"
	var noise_speed = input_vars[8] if input_vars[8] != "" else "0.2"
	var wind_noise = input_vars[9]
	var wind_dir= input_vars[10] if input_vars[10] != "" else "vec2(1.0, 0.0)"
	var OUT = output_vars[0]

	var code := ""

	# 玩家对草的影响
	code += "float dist = length(NODE_POSITION_WORLD - "+player_position+");\n"
	code += "float push_factor = (1.0 - smoothstep("+radius+", "+radius+" + "+falloff+", dist)) *(1.0 - UV.y) * "+strength+" ;\n"
	code += "vec3 dir = normalize(NODE_POSITION_WORLD - " + player_position + ");\n"
	code += "vec3 push_offset = dir * push_factor;\n"

	# 风摆动
	code += "float t = TIME * " + wind_speed + ";\n"
	code += "float sway = sin(VERTEX.x * "+freq+".x + VERTEX.z * "+freq+".y + TIME * "+wind_speed+") * "+wind_strength+" * (1.0-UV.y);\n"

	# 噪声扰动
	code += "float noise = texture(" + wind_noise + ", NODE_POSITION_WORLD.xz * " + noise_scale + " + vec2(TIME*" + noise_speed + ")).r;\n"
	code += "vec3 noise_offset = vec3(normalize("+wind_dir+").x*noise,0.0,normalize("+wind_dir+").y*noise);\n"
	

	# 总偏移
	code += "vec3 offset = noise_offset * sway + push_offset + VERTEX;\n"
	code += OUT + " = offset;\n"

	return code
