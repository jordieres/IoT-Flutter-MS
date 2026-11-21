import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import jdk.internal.org.objectweb.asm.*;

import static jdk.internal.org.objectweb.asm.Opcodes.*;

/**
 * Repairs manual disconnect and rejects invalid stream setup in Sensoria 22.04a.
 * Run with JDK 17:
 * java --add-exports java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED \
 *   android/sdk-tools/PatchSensoriaDisconnect.java original.jar patched.jar
 */
class PatchSensoriaDisconnect {
    private static final String CORE = "com/sensoria/sensorialibrary/SACore";
    private static final String CONNECTION_CALLBACK = CORE + "$13";
    private static final String SERVICE = "com/sensoria/sensorialibrary/SAService";
    private static final String STREAM = "com/sensoria/sensorialibrary/SASensoriaStreamingService";
    private static final String GATT = "android/bluetooth/BluetoothGatt";
    private static final String GATT_TYPE = "L" + GATT + ";";
    private static final String DISCONNECT_TASK_ARGS =
            "(L" + CONNECTION_CALLBACK + ";" + GATT_TYPE + ")V";

    private static boolean isDisconnectTask(String name) {
        return name.equals(CONNECTION_CALLBACK + "$4") ||
                name.equals(CONNECTION_CALLBACK + "$5") ||
                name.equals(CONNECTION_CALLBACK + "$6");
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 2) throw new IllegalArgumentException("Expected original and patched jar paths");
        Path output = Path.of(args[1]);
        Files.copy(Path.of(args[0]), output);
        int[] patches = {0};
        try (var archive = FileSystems.newFileSystem(output, Map.of())) {
            for (String name : new String[] {CORE, CONNECTION_CALLBACK, STREAM, SERVICE,
                    CONNECTION_CALLBACK + "$4", CONNECTION_CALLBACK + "$5", CONNECTION_CALLBACK + "$6"}) {
                Path entry = archive.getPath("/" + name + ".class");
                ClassReader reader = new ClassReader(Files.readAllBytes(entry));
                ClassWriter writer = new ClassWriter(reader, ClassWriter.COMPUTE_MAXS);
                reader.accept(new ClassVisitor(ASM8, writer) {
                    @Override public void visitEnd() {
                        if (isDisconnectTask(name)) {
                            visitField(ACC_PRIVATE | ACC_FINAL, "disconnectedGatt", GATT_TYPE, null, null)
                                    .visitEnd();
                        }
                        super.visitEnd();
                    }

                    @Override public MethodVisitor visitMethod(int access, String method, String descriptor,
                            String signature, String[] exceptions) {
                        if (isDisconnectTask(name) && method.equals("<init>") &&
                                descriptor.equals("(L" + CONNECTION_CALLBACK + ";)V")) {
                            return captureDisconnectedGatt(
                                    super.visitMethod(access, method, DISCONNECT_TASK_ARGS, signature, exceptions),
                                    name, patches);
                        }
                        MethodVisitor visitor = super.visitMethod(access, method, descriptor, signature, exceptions);
                        if (isDisconnectTask(name)) {
                            if (method.equals("run") && descriptor.equals("()V")) {
                                return guardDisconnectTask(visitor, name, patches);
                            }
                        }
                        if (name.equals(CORE) && method.equals("disconnect") && descriptor.equals("()V")) {
                            return new MethodVisitor(ASM8, visitor) {
                                @Override public void visitMethodInsn(int opcode, String owner, String called,
                                        String type, boolean isInterface) {
                                    super.visitMethodInsn(opcode, owner, called, type, isInterface);
                                    if (owner.equals(GATT) && called.equals("close") && type.equals("()V")) {
                                        // close() unregisters the callback. Reset state here instead of
                                        // waiting for a disconnect callback that may never arrive.
                                        visitVarInsn(ALOAD, 0);
                                        visitInsn(ACONST_NULL);
                                        visitFieldInsn(PUTFIELD, CORE, "mConnectedGatt", "L" + GATT + ";");
                                        visitVarInsn(ALOAD, 0);
                                        visitInsn(ICONST_2);
                                        super.visitMethodInsn(INVOKESPECIAL, CORE, "pushState", "(I)V", false);
                                        patches[0]++;
                                    }
                                }
                            };
                        }
                        if (name.equals(CONNECTION_CALLBACK) && method.equals("onConnectionStateChange")
                                && descriptor.equals("(L" + GATT + ";II)V")) {
                            return new MethodVisitor(ASM8, visitor) {
                                @Override public void visitCode() {
                                    super.visitCode();
                                    Label active = new Label();
                                    // A late disconnect from a closed link must not reset a new link.
                                    visitVarInsn(ILOAD, 3);
                                    visitJumpInsn(IFNE, active);
                                    visitVarInsn(ALOAD, 1);
                                    visitVarInsn(ALOAD, 0);
                                    visitFieldInsn(GETFIELD, CONNECTION_CALLBACK, "this$0", "L" + CORE + ";");
                                    visitMethodInsn(INVOKESTATIC, CORE, "access$2200",
                                            "(L" + CORE + ";)L" + GATT + ";", false);
                                    visitJumpInsn(IF_ACMPEQ, active);
                                    visitInsn(RETURN);
                                    visitLabel(active);
                                    visitFrame(F_SAME, 0, null, 0, null);
                                    patches[0]++;
                                }

                                @Override public void visitMethodInsn(int opcode, String owner, String called,
                                        String type, boolean isInterface) {
                                    if (isDisconnectTask(owner) && called.equals("<init>")) {
                                        // The Bluetooth callback and the main-thread task run at different times.
                                        visitVarInsn(ALOAD, 1);
                                        type = DISCONNECT_TASK_ARGS;
                                        patches[0]++;
                                    }
                                    super.visitMethodInsn(opcode, owner, called, type, isInterface);
                                }
                            };
                        }
                        if (name.equals(STREAM) && method.equals("initializeCommand")
                                && descriptor.equals("(Lcom/sensoria/sensorialibrary/ProtocolType;S)Z")) {
                            return new MethodVisitor(ASM8, visitor) {
                                @Override public void visitCode() {
                                    super.visitCode();
                                    Label valid = new Label();
                                    Label invalid = new Label();
                                    // The SDK reads the channel again after preflight. Refuse
                                    // invalid settings if that second read returns bad data.
                                    visitVarInsn(ALOAD, 1);
                                    visitJumpInsn(IFNULL, invalid);
                                    visitVarInsn(ILOAD, 2);
                                    visitJumpInsn(IFGT, valid);
                                    visitLabel(invalid);
                                    visitFrame(F_SAME, 0, null, 0, null);
                                    visitInsn(ICONST_0);
                                    visitInsn(IRETURN);
                                    visitLabel(valid);
                                    visitFrame(F_SAME, 0, null, 0, null);
                                    patches[0]++;
                                }
                            };
                        }
                        if (name.equals(SERVICE) && method.equals("pause") && descriptor.equals("()V")) {
                            return new MethodVisitor(ASM8, visitor) {
                                @Override public void visitMethodInsn(int opcode, String owner, String called,
                                        String type, boolean isInterface) {
                                    if (owner.equals("java/util/concurrent/CountDownLatch")
                                            && called.equals("await") && type.equals("()V")) {
                                        // A lost Bluetooth disconnect callback must not block the UI.
                                        visitLdcInsn(1000L);
                                        visitFieldInsn(GETSTATIC, "java/util/concurrent/TimeUnit", "MILLISECONDS",
                                                "Ljava/util/concurrent/TimeUnit;");
                                        super.visitMethodInsn(INVOKEVIRTUAL, owner, "await",
                                                "(JLjava/util/concurrent/TimeUnit;)Z", false);
                                        visitInsn(POP);
                                        patches[0]++;
                                    } else {
                                        super.visitMethodInsn(opcode, owner, called, type, isInterface);
                                    }
                                }
                            };
                        }
                        return visitor;
                    }
                }, 0);
                Files.write(entry, writer.toByteArray());
            }
        }
        if (patches[0] != 13) {
            Files.deleteIfExists(output);
            throw new IllegalStateException("Unexpected Sensoria SDK layout");
        }
    }

    private static MethodVisitor captureDisconnectedGatt(MethodVisitor visitor, String name, int[] patches) {
        return new MethodVisitor(ASM8, visitor) {
            @Override public void visitInsn(int opcode) {
                if (opcode == RETURN) {
                    visitVarInsn(ALOAD, 0);
                    visitVarInsn(ALOAD, 2);
                    visitFieldInsn(PUTFIELD, name, "disconnectedGatt", GATT_TYPE);
                    patches[0]++;
                }
                super.visitInsn(opcode);
            }
        };
    }

    private static MethodVisitor guardDisconnectTask(MethodVisitor visitor, String name, int[] patches) {
        return new MethodVisitor(ASM8, visitor) {
            @Override public void visitCode() {
                super.visitCode();
                Label stale = new Label();
                Label active = new Label();
                visitVarInsn(ALOAD, 0);
                visitFieldInsn(GETFIELD, name, "disconnectedGatt", GATT_TYPE);
                visitJumpInsn(IFNULL, stale);
                visitVarInsn(ALOAD, 0);
                visitFieldInsn(GETFIELD, name, "disconnectedGatt", GATT_TYPE);
                visitVarInsn(ALOAD, 0);
                visitFieldInsn(GETFIELD, name, "this$1", "L" + CONNECTION_CALLBACK + ";");
                visitFieldInsn(GETFIELD, CONNECTION_CALLBACK, "this$0", "L" + CORE + ";");
                visitMethodInsn(INVOKESTATIC, CORE, "access$2200", "(L" + CORE + ";)" + GATT_TYPE, false);
                visitJumpInsn(IF_ACMPEQ, active);
                visitLabel(stale);
                visitFrame(F_SAME, 0, null, 0, null);
                visitInsn(RETURN);
                visitLabel(active);
                visitFrame(F_SAME, 0, null, 0, null);
                patches[0]++;
            }
        };
    }
}
