EXE = ������.exe		#ָ������ļ�
OBJS = ������.obj		#��Ҫ��Ŀ���ļ�
RES = ������.res		#��Ҫ����Դ�ļ�

LINK_FLAG = /subsystem:windows	#����ѡ��
ML_FLAG = /c /coff		#����ѡ��

$(EXE): $(OBJS) $(RES)
	Link $(LINK_FLAG) $(OBJS) $(RES)

.asm.obj:
	ml $(ML_FLAG) $<
.rc.res:
	rc $<

clean:
	del *.obj
	del *.res
