# --
# Copyright (C) 202 mo-azfar,https://github.com/mo-azfar/OTRS-Znuny-Quick-Note
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Output::HTML::TicketZoom::TicketWidget;

use parent 'Kernel::Output::HTML::Base';

use strict;
use warnings;

use Kernel::Language qw(Translatable);
use Kernel::System::VariableCheck qw(IsHashRefWithData);

our $ObjectManagerDisabled = 1;

sub Run {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
   	my $ParamObject     = $Kernel::OM->Get('Kernel::System::Web::Request');
	
    my %Ticket    = %{ $Param{Ticket} };
    my %AclAction = %{ $Param{AclAction} };
	
	# check permissions
    my $Access = $Kernel::OM->Get('Kernel::System::Ticket')->TicketPermission(
        Type     => 'note',
        TicketID => $Ticket{TicketID},
        UserID   => $Self->{UserID}
    );
	
	# set display options
    $Param{WidgetTitle} = Translatable('Ticket Widget');

    if ( $Access ) 
	{
        $LayoutObject->Block(
            Name => 'SubmitQuickText',
        );
		
		my $Subaction = $ParamObject->GetParam( Param => 'Subaction' ) || '';
		
		if ( $Subaction eq 'AddNote' ) 
		{
			my $QuickText = $ParamObject->GetParam( Param => 'QuickText' ) || 'N/A';
			my $ArticleBackendObject = $Kernel::OM->Get('Kernel::System::Ticket::Article')->BackendForChannel(ChannelName => 'Internal');
			
			my %User = $Kernel::OM->Get('Kernel::System::User')->GetUserData(
				UserID => $Self->{UserID},
			);
			
			my $ArticleVisibility;
			if  ( $Param{Config}->{IsVisibleForCustomer} eq 'NotVisible')
			{
				$ArticleVisibility = 0;
			}
			else
			{
				$ArticleVisibility = 1;
			}
			
			my $ArticleID = $ArticleBackendObject->ArticleCreate(
				TicketID             => $Ticket{TicketID},                 
				SenderType           => "agent",                          
				IsVisibleForCustomer => $ArticleVisibility,                            
				UserID               => $Self->{UserID},                             
				From           => "$User{UserFullname} <$User{UserEmail}>", 
				Subject        => "Feedback from $User{UserFullname}", 
				Body           => $QuickText,                 
				ContentType    => "text/plain; charset=ISO-8859-15",      
				HistoryType    => "AddNote",                         
				HistoryComment => "AddNote from $User{UserFullname}",
				NoAgentNotify    => 0,                                      
			);
			
			#set javascript reload page once
			$Param{JS} = qq~
			<script type="text/javascript">
			window.onload=function(){
				window.location.search = "?Action=AgentTicketZoom;TicketID=$Ticket{TicketID};ArticleID=$ArticleID";
			}
			</script>~,
		}
	}

    my $Output = $LayoutObject->Output(
        TemplateFile => 'AgentTicketZoom/TicketWidget',
        Data         => { %Param, %Ticket, %AclAction },
    );
	
	return {
        Output => $Output,
    };
}

1;
