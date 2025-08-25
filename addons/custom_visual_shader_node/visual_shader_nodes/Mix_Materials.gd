@tool
extends VisualShaderNodeCustom
class_name VisualShaderNode_MaterialBlend4

func _get_name(): return "MaterialBlend4"
func _get_category(): return "Custom/Fragment"
func _get_description(): return "Blend 4 PBR materials (Albedo, Normal, ORM) using a Vector4 weight and a Vector2 UV input."
func _get_return_icon_type(): return VisualShaderNodeCustom.PORT_TYPE_VECTOR_3D

#  输入：Weight(vec4) + 12 张贴图 + UV(vec2) = 14
func _get_input_port_count(): return 14

func _get_input_port_type(port):
	match port:
		0:  return VisualShaderNodeCustom.PORT_TYPE_VECTOR_4D # Weight
		1,4,7,10: return VisualShaderNodeCustom.PORT_TYPE_SAMPLER # Albedo 1~4
		2,5,8,11: return VisualShaderNodeCustom.PORT_TYPE_SAMPLER # Normal 1~4
		3,6,9,12: return VisualShaderNodeCustom.PORT_TYPE_SAMPLER # ORM 1~4 (R=AO, G=Roughness, B=Metallic)
		13: return VisualShaderNodeCustom.PORT_TYPE_VECTOR_2D     # UV_input
		_:  return VisualShaderNodeCustom.PORT_TYPE_SCALAR

func _get_input_port_name(port):
	match port:
		0:  return "Weight"
		1:  return "Albedo1"
		2:  return "Normal1"
		3:  return "ORM1"
		4:  return "Albedo2"
		5:  return "Normal2"
		6:  return "ORM2"
		7:  return "Albedo3"
		8:  return "Normal3"
		9:  return "ORM3"
		10: return "Albedo4"
		11: return "Normal4"
		12: return "ORM4"
		13: return "UV_input"
		_:  return ""

#  输出：Albedo(vec3), Normal(vec3), Metallic(float), Roughness(float), AO(float)
func _get_output_port_count(): return 5

func _get_output_port_type(port):
	match port:
		0: return VisualShaderNodeCustom.PORT_TYPE_VECTOR_3D # Albedo
		1: return VisualShaderNodeCustom.PORT_TYPE_VECTOR_3D # Normal (tangent space, -1~1)
		2: return VisualShaderNodeCustom.PORT_TYPE_SCALAR     # Metallic
		3: return VisualShaderNodeCustom.PORT_TYPE_SCALAR     # Roughness
		4: return VisualShaderNodeCustom.PORT_TYPE_SCALAR     # AO
		_: return VisualShaderNodeCustom.PORT_TYPE_SCALAR

func _get_output_port_name(port):
	match port:
		0: return "Albedo"
		1: return "Normal"
		2: return "Metallic"
		3: return "Roughness"
		4: return "AO"
		_: return ""

func _get_code(input_vars, output_vars, mode, type):
	var W  = input_vars[0]
	var A1 = input_vars[1];  var N1 = input_vars[2];  var O1 = input_vars[3]
	var A2 = input_vars[4];  var N2 = input_vars[5];  var O2 = input_vars[6]
	var A3 = input_vars[7];  var N3 = input_vars[8];  var O3 = input_vars[9]
	var A4 = input_vars[10]; var N4 = input_vars[11]; var O4 = input_vars[12]
	var UV = input_vars[13]

	var code := ""
	code += "vec4 w = " + W + ";\n"
	code += "w /= max(dot(w, vec4(1.0)), 0.0001);\n" # 归一化权重，避免全零

	# --- Albedo 混合（线性混合）
	code += "vec3 albedo = "
	code += "texture(" + A1 + ", " + UV + ").rgb * w.x + "
	code += "texture(" + A2 + ", " + UV + ").rgb * w.y + "
	code += "texture(" + A3 + ", " + UV + ").rgb * w.z + "
	code += "texture(" + A4 + ", " + UV + ").rgb * w.w;\n"

	# --- Normal 混合：先解包到 [-1,1]，再按权重线性混合并归一化（简单可用；更精确可用 RNM）
	code += "vec3 n1 = texture(" + N1 + ", " + UV + ").rgb * 2.0 - 1.0;\n"
	code += "vec3 n2 = texture(" + N2 + ", " + UV + ").rgb * 2.0 - 1.0;\n"
	code += "vec3 n3 = texture(" + N3 + ", " + UV + ").rgb * 2.0 - 1.0;\n"
	code += "vec3 n4 = texture(" + N4 + ", " + UV + ").rgb * 2.0 - 1.0;\n"
	code += "vec3 normal_ts = normalize(n1 * w.x + n2 * w.y + n3 * w.z + n4 * w.w);\n"

	# --- ORM 混合（R=AO, G=Roughness, B=Metallic）
	code += "vec3 orm = "
	code += "texture(" + O1 + ", " + UV + ").rgb * w.x + "
	code += "texture(" + O2 + ", " + UV + ").rgb * w.y + "
	code += "texture(" + O3 + ", " + UV + ").rgb * w.z + "
	code += "texture(" + O4 + ", " + UV + ").rgb * w.w;\n"

	# --- 输出
	code += output_vars[0] + " = albedo;\n"
	code += output_vars[1] + " = normal_ts;\n"
	code += output_vars[2] + " = orm.b;\n" # Metallic
	code += output_vars[3] + " = orm.g;\n" # Roughness
	code += output_vars[4] + " = orm.r;\n" # AO

	return code
